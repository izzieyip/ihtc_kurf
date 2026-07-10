package ihtcvirtualpreprocessing;

import java.io.File;
import java.io.IOException;
import java.util.*;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.*;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl;

/**
 * Extends a domain metamodel .ecore file to include virtual node/eClasses 
 * Currently only creates virtual nodes with all references set between source/target classes, but not between virtual nodes. 
 * 
 * TODO : Use domain GT rules to add dependencies (requires/enables) to virtual nodes
 * Would require using the Ihtpdomaingtrules API
 */
public class MetamodelExtender{

	private static final String VIRTUAL_ANNOTATION_SOURCE = "virtualNode";
	private final EPackage ePackage;

	private MetamodelExtender(EPackage ePackage) {
		this.ePackage = ePackage;
	}

	public static void main(String[] args) throws IOException {
		if (args.length < 2) {
			throw new IllegalArgumentException("Missing arguments - [input ecore path, output ecore path]");
		}

		EPackage domainMetamodel = loadEcoreMetamodel(args[0]);
		MetamodelExtender extender = new MetamodelExtender(domainMetamodel);
		extender.createVirtualNodes();
		saveEcoreMetamodel(domainMetamodel, args[1]);
		System.out.println("Output saved to: " + args[1]);
	}

	/**
	 * Creates virtual nodes for all derived reference pairs.
	 */
	private Map<String, EClass> createVirtualNodes() {
		Map<String, EClass> virtualNodesByName = new HashMap<>();

		findDerivedReferencePairs(ePackage).values().forEach(pair -> {
			EClass virtualClass = createVirtualClassForPair(pair[0], pair[1], ePackage);
			addVirtualReferencesToBaseClasses(pair[0], pair[1], virtualClass);
			virtualNodesByName.put(virtualClass.getName(), virtualClass);
		});

		return virtualNodesByName;
	}


	/**
	 * Simple class to hold virtual node info
	 */
	static class VirtualNodeInfo {
		String source;
		String target;
		EClass eclass;

		VirtualNodeInfo(String source, String target, EClass eclass) {
			this.source = source;
			this.target = target;
			this.eclass = eclass;
		}
	}

	/**
	 * Finds pairs of derived edges, by references starting with derived
	 * 
	 * This solution is not very robust. In future it would be good to have derived edges and virtual nodes be different types of eClasses.
	 * 
	 * @param ePackage
	 * @return Map<String, EReference[]>  
	 */
	private static Map<String, EReference[]> findDerivedReferencePairs(EPackage ePackage) {
		Map<String, EReference[]> pairs = new LinkedHashMap<>();
		Set<EReference> processed = new HashSet<>();

		ePackage.getEClassifiers().stream().filter(EClass.class::isInstance).map(EClass.class::cast)
				.flatMap(eClass -> eClass.getEStructuralFeatures().stream()).filter(EReference.class::isInstance)
				.map(EReference.class::cast).filter(ref -> ref.getName().startsWith("derived"))
				.filter(ref -> !processed.contains(ref)).forEach(ref -> {
					EReference opposite = ref.getEOpposite();
					if (opposite != null && !processed.contains(opposite)) {
						String key = createPairKey(ref, opposite);
						pairs.put(key, new EReference[] { ref, opposite });
						processed.add(ref);
						processed.add(opposite);
					}
				});

		return pairs;
	}
	
	/**
	 * Creates a reference pair with consistent alphabetical name ordering
	 * 
	 * @param EReference ref1
	 * @param EReference ref2
	 * @return String pair name
	 */
	private static String createPairKey(EReference ref1, EReference ref2) {
		String name1 = ref1.getEContainingClass().getName();
		String name2 = ref2.getEContainingClass().getName();
		return name1.compareTo(name2) < 0 ? name1 + "-" + name2 : name2 + "-" + name1;
	}

	private static class RefPair {
		final EClass containerClass;
		final EClass referencedClass;
		final EReference containerRef;
		final EReference referencedRef;

		RefPair(EReference ref1, EReference ref2) {
			if (ref1.getUpperBound() == -1 || ref1.getUpperBound() > 1) {
				this.containerClass = ref1.getEContainingClass();
				this.referencedClass = (EClass) ref1.getEType();
				this.containerRef = ref1;
				this.referencedRef = ref2;
			} else {
				this.containerClass = (EClass) ref1.getEType();
				this.referencedClass = ref1.getEContainingClass();
				this.containerRef = ref2;
				this.referencedRef = ref1;
			}
		}
	}

	private static EClass createVirtualClassForPair(EReference ref1, EReference ref2, EPackage ePackage) {
		RefPair pair = new RefPair(ref1, ref2);
		String virtualClassName = "Virtual" + pair.containerClass.getName() + "To" + pair.referencedClass.getName();

		EClass virtualClass = EcoreFactory.eINSTANCE.createEClass();
		virtualClass.setName(virtualClassName);
		ePackage.getEClassifiers().add(virtualClass);

		addVirtualMetadata(virtualClass, pair);
		addVirtualClassReferences(virtualClass, pair);

		return virtualClass;
	}

	private static void addVirtualMetadata(EClass virtualClass, RefPair pair) {
		EAnnotation annotation = EcoreFactory.eINSTANCE.createEAnnotation();
		annotation.setSource(VIRTUAL_ANNOTATION_SOURCE);
		annotation.getDetails().put("sourceClass", pair.containerClass.getName());
		annotation.getDetails().put("targetClass", pair.referencedClass.getName());
		annotation.getDetails().put("sourceReference", uncapitalize(pair.containerClass.getName()));
		annotation.getDetails().put("targetReference", uncapitalize(pair.referencedClass.getName()));
		annotation.getDetails().put("sourceEdgeReference", pair.containerRef.getName());
		annotation.getDetails().put("targetEdgeReference", pair.referencedRef.getName());
		virtualClass.getEAnnotations().add(annotation);
	}

	private static void addVirtualClassReferences(EClass virtualClass, RefPair pair) {
		addEReference(virtualClass, uncapitalize(pair.containerClass.getName()), pair.containerClass);
		addEReference(virtualClass, uncapitalize(pair.referencedClass.getName()), pair.referencedClass);

		EAttribute isSelected = EcoreFactory.eINSTANCE.createEAttribute();
		isSelected.setName("isSelected");
		isSelected.setEType(EcorePackage.Literals.EBOOLEAN);
		virtualClass.getEStructuralFeatures().add(isSelected);
	}

	private static EReference addEReference(EClass eClass, String name, EClass refType) {
		EReference ref = EcoreFactory.eINSTANCE.createEReference();
		ref.setName(name);
		ref.setEType(refType);
		eClass.getEStructuralFeatures().add(ref);
		return ref;
	}

	private static void addVirtualReferencesToBaseClasses(EReference ref1, EReference ref2, EClass virtualClass) {
		RefPair pair = new RefPair(ref1, ref2);

		EReference containerReference = addEReference(pair.containerClass,
				"virtual" + capitalize(pair.referencedClass.getName()), virtualClass);
		containerReference.setContainment(true);
		containerReference.setUpperBound(-1);

		EReference referencedReference = addEReference(pair.referencedClass,
				"virtual" + capitalize(pair.containerClass.getName()), virtualClass);
		referencedReference.setUpperBound(-1);

		setEOpposites(virtualClass, pair, containerReference, referencedReference);
	}

	private static void setEOpposites(EClass virtualClass, RefPair pair, EReference containerRef,
			EReference referencedRef) {
		EReference refToContainer = (EReference) virtualClass
				.getEStructuralFeature(uncapitalize(pair.containerClass.getName()));
		EReference refToReferenced = (EReference) virtualClass
				.getEStructuralFeature(uncapitalize(pair.referencedClass.getName()));

		containerRef.setEOpposite(refToContainer);
		refToContainer.setEOpposite(containerRef);
		referencedRef.setEOpposite(refToReferenced);
		refToReferenced.setEOpposite(referencedRef);
	}

	private static String uncapitalize(String str) {
		if (str == null || str.length() == 0)
			return str;
		return Character.toLowerCase(str.charAt(0)) + str.substring(1);
	}

	private static String capitalize(String str) {
		if (str == null || str.length() == 0)
			return str;
		return Character.toUpperCase(str.charAt(0)) + str.substring(1);
	}

	private static EPackage loadEcoreMetamodel(String filePath) throws IOException {
		ResourceSet resourceSet = new ResourceSetImpl();
		resourceSet.getResourceFactoryRegistry().getExtensionToFactoryMap().put("ecore",
				new EcoreResourceFactoryImpl());

		File ecoreFile = new File(filePath);
		if (!ecoreFile.exists()) {
			throw new IOException("File not found: " + ecoreFile.getAbsolutePath());
		}

		URI uri = URI.createFileURI(ecoreFile.getAbsolutePath());
		Resource resource = resourceSet.getResource(uri, true);
		return (EPackage) resource.getContents().get(0);
	}

	private static void saveEcoreMetamodel(EPackage ePackage, String filePath) throws IOException {
		ResourceSet resourceSet = new ResourceSetImpl();
		resourceSet.getResourceFactoryRegistry().getExtensionToFactoryMap().put("ecore",
				new EcoreResourceFactoryImpl());

		File outputFile = new File(filePath);
		outputFile.getParentFile().mkdirs();

		URI uri = URI.createFileURI(outputFile.getAbsolutePath());
		Resource resource = resourceSet.createResource(uri);
		resource.getContents().add(ePackage);
		resource.save(Collections.emptyMap());
	}
}