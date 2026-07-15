package ihtcvirtualpostprocessing

import java.io.File
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Paths
import java.util.logging.Logger
import org.apache.commons.lang3.StringUtils
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EAnnotation
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl

/**
 * Generator to automatically produce an Emoflon set of post-processing GT rules, given a virtual metamodel.
 */
class GTRuleAutomation {

	EPackage metamodel
	String ecorePath
	static int id = 1

	protected val logger = Logger.getLogger(GTRuleAutomation.name)

	static class VirtualNodeInfo {
		String className
		String sourceClass
		String targetClass
		String sourceRef
		String targetRef
		String sourceEdgeReference
		String targetEdgeReference

		new(String name, String sClass, String tClass, String sRef, String tRef, String sEdge, String tEdge) {
			this.className = name
			this.sourceClass = sClass
			this.targetClass = tClass
			this.sourceRef = sRef
			this.targetRef = tRef
			this.sourceEdgeReference = sEdge
			this.targetEdgeReference = tEdge
		}

		def getName() {
			this.className
		}
	}

	/**
	 * Constructor - loads the metamodel
	 */
	new(String inputPath) throws IOException {
		this.ecorePath = inputPath
		this.metamodel = loadEcoreMetamodel(ecorePath)

		System.out.println("Metamodel loaded: " + metamodel.name)
		System.out.println("Number of classes: " + metamodel.EClassifiers.size)
	}

	private def EPackage loadEcoreMetamodel(String path) throws IOException {
		val resourceSet = new ResourceSetImpl()
		resourceSet.resourceFactoryRegistry.extensionToFactoryMap.put("ecore", new EcoreResourceFactoryImpl())

		val ecoreFile = new File(path)

		if (!ecoreFile.exists()) {
			throw new IOException("File not found: " + ecoreFile.absolutePath)
		}

		val uri = URI.createFileURI(ecoreFile.absolutePath)
		val resource = resourceSet.getResource(uri, true)

		return resource.contents.get(0) as EPackage
	}

	/**
	 * Generate all rules from virtual node annotations
	 */
	def generateRules() '''
		import "platform:/resource/«StringUtils.stripStart(ecorePath, "./")»"
		
		«metamodel.EClassifiers.filter(EClass).map[generateEClassRules].filter[!empty] .join('\n')»
	'''

	private def generateEClassRules(EClass eClass) {
		System.out.println("Checking class: " + eClass.name)
		val info = getVirtualNodeInfo(eClass)

		if (info !== null)
			'''
				«info.generateConversionRule»
				«info.generateRemovalRule»
			'''
		else
			''
	}

	private def getVirtualNodeInfo(EClass eClass) {
		for (EAnnotation annotation : eClass.EAnnotations) {
			if ("virtualNode" == annotation.source) {
				val sourceClass = annotation.details.get("sourceClass")
				val targetClass = annotation.details.get("targetClass")
				val sourceRef = annotation.details.get("sourceReference")
				val targetRef = annotation.details.get("targetReference")
				val sourceEdge = annotation.details.get("sourceEdgeReference")
				val targetEdge = annotation.details.get("targetEdgeReference")

				return new VirtualNodeInfo(
					eClass.name,
					sourceClass,
					targetClass,
					sourceRef,
					targetRef,
					sourceEdge,
					targetEdge
				)
			}
		}

		System.out.println("Checking class: " + eClass.name + " | Annotations: " + eClass.EAnnotations.size)
		for (EAnnotation annotation : eClass.EAnnotations) {
			System.out.println("  Found annotation: " + annotation.source)
		}
		return null
	}

	/**
	 * Generate the conversion rule (e.g., virtualShiftToWorkload_to_derived)
	 */
	private def generateConversionRule(VirtualNodeInfo info) {
		val camelCaseClass = info.className.substring(0, 1).toLowerCase + info.className.substring(1)
		val ruleName = camelCaseClass + "ToDerived"

		val vVar = getVariableName(info.className)
		val sourceVar = getVariableName(info.sourceClass)
		val targetVar = getVariableName(info.targetClass)

		val sourceVirtualRef = "virtual" + info.targetClass
		val targetVirtualRef = "virtual" + info.sourceClass

		'''
			//
			// Remove objects of the type `«info.className»`
			//
			rule «ruleName» {
				-- «vVar» : «info.className» {
					-- -«info.sourceRef» -> «sourceVar»
					-- -«info.targetRef» -> «targetVar»
				}
			
				«sourceVar» : «info.sourceClass» {
				++ -«info.sourceEdgeReference» -> «targetVar»
				-- -«sourceVirtualRef» -> «vVar»
				}
			
				«targetVar» : «info.targetClass» {
				++ -«info.targetEdgeReference» -> «sourceVar»
				-- -«targetVirtualRef» -> «vVar»
				}
				
				# «vVar».isSelected == true
			}
		'''
	}

	/**
	 * Generate the removal rule (e.g., removeVirtualShiftToWorkload)
	 */
	private def generateRemovalRule(VirtualNodeInfo info) {
		val ruleName = "remove" + info.className
		val vVar = getVariableName(info.className)

		'''
			rule «ruleName» {
				-- «vVar» : «info.className»
				# «vVar».isSelected == false
			}
		'''
	}

	/**
	 * Get a short variable name (e.g., "Shift" -> "s", "Workload" -> "w")
	 * Each name will be unique by the incremented static class id attribute
	 */
	private def getVariableName(String className) {
		val varName = className.substring(0, 1).toLowerCase
		val uniqueVar = varName + "_" + id++;

		return uniqueVar
	}

	/**
	 * Write the generated GT rules to a file
	 */
	def writeToFile(String outputPath) throws IOException {
		val path = Paths.get(outputPath)

		if (path.parent !== null) {
			Files.createDirectories(path.parent)
		}

		Files.write(path, generateRules.toString.bytes)
		System.out.println("\nGenerated at: " + outputPath)
	}

	/**
	 * Main method - creates instance and runs automator
	 * 
	 * Suggested arguments:
	 * "../ihtcvirtualmetamodel/model/Ihtcvirtualmetamodel.ecore"
	 * "src/ihtcvirtualpostprocessing/PostProcessingGTRules.gt"
	 */
	def static void main(String[] args) throws IOException {
		if (args.length < 2) {
			throw new IllegalArgumentException("Missing arguments - [input ecore path, output GT path]")
		}
		val automator = new GTRuleAutomation(args.get(0))

		automator.writeToFile(args.get(1))

		System.out.println("GT Rules generated successfully")
	}
}
