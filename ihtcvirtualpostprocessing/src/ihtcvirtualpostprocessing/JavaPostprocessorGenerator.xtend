package ihtcvirtualpostprocessing

import java.io.File
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Paths
import java.util.List
import java.util.logging.Logger
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl

import static extension gips.examples.dependencies.GipsExamplesLogger.*

/**
 * Simple Virtual Node object class to store eAnnotations
 */
class VirtualNode {
	public String name
	public String sourceReference
	public String targetReference
	public String sourceEdge
	public String targetEdge

	new(String className) {
		this.name = className
	}
}

/**
 * Generates a Java Postprocessor based on ecore annotations.
 */
class JavaPostprocessorGenerator {

	static var EPackage metamodel;
	static var String metamodelPackageName
	static var String newFileName

	protected static val logger = Logger.getLogger(JavaPostprocessorGenerator.name)

	/**
	 * Example arguments:
	 * ihtcvirtualpostprocessing
	 * src/ihtcvirtualpostprocessing/JavaPostprocessor.java
	 * ../ihtcvirtualmetamodel/model/Ihtcvirtualmetamodel.ecore
	 */
	def static void main(String[] args) throws Exception {
		if (args.length < 3) {
			logger.warning("Program missing arguments. Arguments should be:")
			logger.warning("1. Output package (e.g. org.emoflon.gips.ihtc.virtual.postprocessor)")
			logger.warning("2. Output file path")
			logger.warning("3. Ecore file path")
			System.exit(1)
		}

		new JavaPostprocessorGenerator(args.get(0), args.get(1), args.get(2))
	}

	new(String outputPackage, String outputFilePath, String ecoreFilePath) throws Exception {
		logger.configureLogging
		metamodel = loadEcoreMetamodel(ecoreFilePath)
		metamodelPackageName = metamodel.name.toLowerCase
		newFileName = extractClassNameFromPath(outputFilePath)
		logger.info("Metamodel loaded \n")

		val virtualNodeClasses = findVirtualNodeClasses(metamodel)
		logger.info("Found " + virtualNodeClasses.size() + " virtual node class(es) \n:")

		val virtualNodeInfoMap = getVirtualNodes(virtualNodeClasses)
		logger.info("Metadata extracted for all virtual nodes \n")

		val generatedCode = generatePostprocessor(outputPackage, virtualNodeInfoMap)
		logger.info("Code generated \n")

		val outputFile = new File(outputFilePath)
		outputFile.parentFile.mkdirs()
		Files.write(Paths.get(outputFilePath), generatedCode.bytes)
		logger.info("File written successfully to: " + outputFilePath)
	}

	/**
	 * Find all virtual node classes in the .ecore metamodel
	 */
	private def List<EClass> findVirtualNodeClasses(EPackage ePackage) {
		ePackage.EClassifiers.filter(EClass).filter[getEAnnotation("virtualNode") !== null].toList();
	}

	/**
	 * Get a list of VirtualNode objects, with the metadata set
	 */
	private def List<VirtualNode> getVirtualNodes(List<EClass> virtualNodeList) {
		virtualNodeList.map [ node |
			val annotation = node.getEAnnotation("virtualNode")
			if (annotation !== null) {
				val virtualNode = new VirtualNode(node.name)
				virtualNode.sourceReference = annotation.details.get("sourceReference")
				virtualNode.targetReference = annotation.details.get("targetReference")
				virtualNode.sourceEdge = annotation.details.get("sourceEdgeReference")
				virtualNode.targetEdge = annotation.details.get("targetEdgeReference")

				virtualNode
			} else {
				null
			}
		].filterNull.toList()
	}

	/**
	 * Generates the Java postprocessor file
	 * 
	 * @param String - package name of file
	 * @param List<VirtualNode> - list of Virtual Node objects
	 * 
	 * @return String - the generated Java file
	 */
	def String generatePostprocessor(String packageName, List<VirtualNode> virtualNodes) {

		'''
			package «packageName»;
			
			import java.io.IOException;
			import java.util.Objects;
			import java.util.logging.ConsoleHandler;
			import java.util.logging.Formatter;
			import java.util.logging.LogRecord;
			import java.util.logging.Logger;
			import java.util.ArrayList;
			import java.util.Iterator;
			import java.util.List;
			
			import org.eclipse.emf.ecore.EObject;
			import org.eclipse.emf.ecore.util.EcoreUtil;
			import org.emoflon.smartemf.persistence.SmartEMFResourceFactoryImpl;
			
			import «metamodelPackageName».«toTitleCase(metamodelPackageName)»Package;
			import «metamodelPackageName».Root;
			import «metamodelPackageName».utils.FileUtils;
			import «metamodelPackageName».*;
			
			/**
			 * Auto-generated Virtual Node Post-Processor.
			 * 
			 * This class processes virtual nodes from the model:
			 *   1. Loads the XMI model
			 *   2. Finds all virtual node instances
			 *   3. If selected, produce derived edges between source and target
			 *   4. Deletes all virtual nodes
			 *   5. Saves the transformed model
			 */
			public class «newFileName» {
			    
			    protected final Logger logger = Logger.getLogger(JavaPostprocessor.class.getName());
			    
			    private final String xmiInputFilePath;
			    private final String xmiOutputFilePath;
			    private Root model;
			    
			    public «newFileName»(final String xmiInputFilePath, final String xmiOutputFilePath) {
			        Objects.requireNonNull(xmiInputFilePath);
			        Objects.requireNonNull(xmiOutputFilePath);
			        
			        this.xmiInputFilePath = xmiInputFilePath;
			        this.xmiOutputFilePath = xmiOutputFilePath;
			        
			        logger.setUseParentHandlers(false);
			        final ConsoleHandler handler = new ConsoleHandler();
			        handler.setFormatter(new Formatter() {
			            @Override
			            public String format(final LogRecord record) {
			                return record.getMessage() + System.lineSeparator();
			            }
			        });
			        logger.addHandler(handler);
			    }
			    
			    /**
			     * Main execution method.
			     */
			    public void run() {
			        try {
			            logger.info("  Virtual Node Post-Processing (Auto-Generated)");
			            
			            logger.info("Loading model from: " + xmiInputFilePath);
			            model = loadModel(xmiInputFilePath);
			            logger.info("Model loaded");
			            
			            logger.info("Processing virtual nodes...");
			            processVirtualNodes(model);
			            logger.info("Virtual nodes processed");
			            
			            logger.info("Saving transformed model to: " + xmiOutputFilePath);
			            saveModel(model, xmiOutputFilePath);
			            logger.info("Model saved");
			            
			            logger.info("Post-processing complete!");
			            
			        } catch (final IOException e) {
			            logger.warning("IOException: " + e.getMessage());
			            e.printStackTrace();
			            System.exit(1);
			        }
			    }
			    
			    /**
			     * Find all virtual nodes
			     * Perform logic on each type
			     * Delete all virtual nodes
			     */
			    private void processVirtualNodes(Root root) {
			        logger.info("  Finding all virtual nodes... ");
			        
			        List<EObject> virtualNodesToDelete = new ArrayList<>();
			        
			        // Get all objects in the model
			        Iterator<EObject> iterator = root.eAllContents();
			        while (iterator.hasNext()) {
			        	EObject obj = iterator.next();
			        	   String className = obj.eClass().getName();
			        	   
			        	   «generateVirtualNodeChecks(virtualNodes)»
			        }
			        
			        // Remove all virtual nodes
			        logger.info("  Deleting virtual nodes...");
			        for (EObject virtualNode : virtualNodesToDelete) {
			            EcoreUtil.remove(virtualNode);
			        }
			        logger.info("  Deleted virtual nodes");
			    }
			    
			    «generateProcessMethods(virtualNodes)»
			    
			    private Root loadModel(final String path) throws IOException {
			        Objects.requireNonNull(path);
			        final org.eclipse.emf.ecore.resource.ResourceSet rs = 
			            new org.eclipse.emf.ecore.resource.impl.ResourceSetImpl();
			        final org.eclipse.emf.ecore.resource.Resource.Factory.Registry reg = 
			            org.eclipse.emf.ecore.resource.Resource.Factory.Registry.INSTANCE;
			        reg.getExtensionToFactoryMap().put("xmi", new SmartEMFResourceFactoryImpl("../"));
			        rs.getPackageRegistry().put(
			            «toTitleCase(metamodelPackageName)»Package.eNS_URI, 
			            «toTitleCase(metamodelPackageName)»Package.eINSTANCE
			        );
			        final org.eclipse.emf.ecore.resource.Resource resource = rs.getResource(
			            org.eclipse.emf.common.util.URI.createFileURI(path), true
			        );
			        return (Root) resource.getContents().get(0);
			    }
			    
			    private void saveModel(final Root model, final String path) throws IOException {
			        Objects.requireNonNull(model);
			        Objects.requireNonNull(path);
			        FileUtils.save(model, path);
			    }
			    
			}
		'''
	}

	/**
	 * Generate the if-else chain to check each virtual node type
	 */
	private def generateVirtualNodeChecks(List<VirtualNode> virtualNodes) '''
		«virtualNodes.map[generateVirtualNodeChecks].join(' else ')»
	'''

	private def generateVirtualNodeChecks(VirtualNode vn) '''
		if (className.equals("«vn.name»")) {
		  process_«vn.name»(obj);
		  virtualNodesToDelete.add(obj);
		}
	'''

	/**
	 * Creates derived edges if virtual node is selected
	 * 
	 */
	private def String generateProcessMethods(List<VirtualNode> virtualNodes) {
		virtualNodes.map[generateProcessMethod(it)].join("\n\n")
	}

	private def String generateProcessMethod(VirtualNode vn) '''
		private void process_«vn.name»(EObject virtualNode) {
		        «vn.name» vNode = («vn.name») virtualNode;
		        Object source = vNode.get«vn.sourceReference.toFirstUpper»();
		        Object target = vNode.get«vn.targetReference.toFirstUpper»();
		        
		        if (vNode.isIsSelected()) {
		        	((«vn.sourceReference.toFirstUpper») source).«assignDerivedEdges(vn.sourceReference, vn.sourceEdge)»((«vn.targetReference.toFirstUpper») target);
		        	((«vn.targetReference.toFirstUpper»)target).«assignDerivedEdges(vn.targetReference, vn.targetEdge)»((«vn.sourceReference.toFirstUpper») source);
		    	}
		}
	'''

	/**
	 * Uses getDerived.add(target) if derived edge is a collection
	 * Uses setDerived(target) if derived edge is singular
	 */
	private def String assignDerivedEdges(String baseClassName, String derivedEdge) {
		val EClass baseClass = metamodel.eAllContents.filter(EClass).findFirst[name == baseClassName.toFirstUpper]
		val int multiplicity = baseClass.EAllStructuralFeatures.findFirst[name == derivedEdge].upperBound;
		if (multiplicity == -1) {
			'''get«derivedEdge.toFirstUpper»().add'''
		} else {

			'''set«derivedEdge.toFirstUpper»'''
		}

	}

	/**
	 * Load the Ecore metamodel
	 */
	private def EPackage loadEcoreMetamodel(String ecorePath) throws IOException {
		val ResourceSet resourceSet = new ResourceSetImpl()
		resourceSet.getResourceFactoryRegistry().getExtensionToFactoryMap().put("ecore", new EcoreResourceFactoryImpl())

		val File ecoreFile = new File(ecorePath)

		if (!ecoreFile.exists()) {
			throw new IOException("File not found: " + ecoreFile.getAbsolutePath())
		}

		val URI uri = URI.createFileURI(ecoreFile.getAbsolutePath())
		val Resource resource = resourceSet.getResource(uri, true)

		return resource.getContents().get(0) as EPackage
	}

	/**
	 * Convert package name to title case for class names
	 * "ihtcvirtualmetamodel" -> "Ihtcvirtualmetamodel"
	 */
	private def String toTitleCase(String packageName) {
		if(packageName === null || packageName.isEmpty()) return packageName
		return packageName.substring(0, 1).toUpperCase() + packageName.substring(1)
	}

	/**
	 * Get the class name from the given output file path
	 */
	private def String extractClassNameFromPath(String outputFilePath) {
		val fileName = Paths.get(outputFilePath).getFileName().toString()
		return fileName.substring(0, fileName.lastIndexOf('.'))
	}

}
