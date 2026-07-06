package org.emoflon.gips.ihtc.virtual.runner

import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EAnnotation
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import java.io.File
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Paths
import java.util.ArrayList
import java.util.List
import java.util.HashMap
import java.util.Map

/**
 * 
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
    
    def static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.err.println("Program missing arguments. Arguments should be:")
            System.err.println("1. Output package (e.g org.emoflon.gips.ihtc.virtual.postprocessor)")
            System.err.println("2. Output file path")
            System.exit(1)
        }
        
        val outputPackage = args.get(0)
        val outputFilePath = args.get(1)
        
        val generator = new JavaPostprocessorGenerator()
        generator.generate(outputPackage, outputFilePath)
    }
    
    def void generate(String outputPackage, String outputFilePath) throws Exception {
        println("JavaPostprocessor Generator")
        println()
        
        println("Loading metamodel...")
        val ePackage = loadEcoreMetamodel()
        println("Metamodel loaded")
        println()
        
        println("Finding virtual node classes...")
        val virtualNodeClasses = findVirtualNodeClasses(ePackage)
        println("Found " + virtualNodeClasses.size() + " virtual node class(es):")
        virtualNodeClasses.forEach[cn | println("    - " + cn.name)]
        println()
        
        println("Extracting virtual node metadata...")
        val virtualNodeInfoMap = getVirtualNodes(virtualNodeClasses)
        println("Metadata extracted for all virtual nodes")
        println()
        
        println("Generating JavaPostprocessor class...")
        val generatedCode = generatePostprocessor(outputPackage, virtualNodeInfoMap)
        println("Code generated")
        println()
        
        println("Writing to file...")
        println("Output: " + outputFilePath)
        val outputFile = new File(outputFilePath)
        outputFile.parentFile.mkdirs()
        Files.write(Paths.get(outputFilePath), generatedCode.bytes)
        println("File written successfully")
        println()
        
        println("Generation complete.")
    }
    
    /**
     * Find all virtual node classes in the .ecore metamodel
     */
    private def List<EClass> findVirtualNodeClasses(EPackage ePackage) {
        val virtualNodeClasses = new ArrayList<EClass>()
        ePackage.getEClassifiers().forEach [ classifier |
            if (classifier instanceof EClass) {
                val eClass = classifier as EClass
                if (eClass.getEAnnotation("virtualNode") !== null) {
                    virtualNodeClasses.add(eClass)
                }
            }
        ]
        return virtualNodeClasses
    }
    
    /**
     * Get a list of VirtualNode objects, with the metadata set
     */
    private def List<VirtualNode> getVirtualNodes(List<EClass> virtualNodeList) {
    	// a map of String names to VirtualNode objects
        val virtualNodeMap = new ArrayList<VirtualNode>
        
        for (node : virtualNodeList) {
            val annotation = node.getEAnnotation("virtualNode")
            
            if (annotation !== null) {
                val virtualNode = new VirtualNode(node.name)
                
                for (detail : annotation.details.entrySet()) {
                    val key = detail.key
                    val value = detail.value
                    
                    if (key == "sourceReference") {
                        virtualNode.sourceReference = value
                    } else if (key == "targetReference") {
                        virtualNode.targetReference = value
                    } else if (key == "sourceEdgeReference") {
                    	virtualNode.sourceEdge = value
                    }  if (key == "targetEdgeReference") {
                    	virtualNode.targetEdge = value
                    }
                }
                
                virtualNodeMap.add(virtualNode)
            }
        }
        
        return virtualNodeMap
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
        import java.lang.reflect.Method;
        import java.util.Objects;
        import java.util.logging.ConsoleHandler;
        import java.util.logging.Formatter;
        import java.util.logging.LogRecord;
        import java.util.logging.Logger;
        import java.util.ArrayList;
        import java.util.Iterator;
        import java.util.List;
        
        import org.eclipse.emf.common.util.EList;
        import org.eclipse.emf.ecore.EObject;
        import org.eclipse.emf.ecore.EStructuralFeature;
        import org.eclipse.emf.ecore.util.EcoreUtil;
        import org.emoflon.smartemf.persistence.SmartEMFResourceFactoryImpl;
        import org.emoflon.smartemf.runtime.collections.LinkedSmartESet;
        import org.emoflon.smartemf.runtime.collections.SmartESet;
        
        import ihtcvirtualmetamodel.IhtcvirtualmetamodelPackage;
        import ihtcvirtualmetamodel.Root;
        import ihtcvirtualmetamodel.utils.FileUtils;
        import ihtcvirtualmetamodel.*;
        
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
        public class JavaPostprocessor {
            
            protected final Logger logger = Logger.getLogger(JavaPostprocessor.class.getName());
            
            private final String xmiInputFilePath;
            private final String xmiOutputFilePath;
            private Root model;
            
            public JavaPostprocessor(final String xmiInputFilePath, final String xmiOutputFilePath) {
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
                } catch (final Exception e) {
                    logger.warning("Error: " + e.getMessage());
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
                    
                    logger.info(className);
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
                    IhtcvirtualmetamodelPackage.eNS_URI, 
                    IhtcvirtualmetamodelPackage.eINSTANCE
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
    private def String generateVirtualNodeChecks(List<VirtualNode> virtualNodes) {
        val sb = new StringBuilder()
        
        for (vn : virtualNodes) {
            sb.append('''
                    if (className.equals("«vn.name»")) {
                        process_«vn.name»(obj);
                        virtualNodesToDelete.add(obj);
                    } else ''')
        }
        
        // Remove the last "else"
        val result = sb.toString()
        if (result.endsWith("else ")) {
            return result.substring(0, result.length() - 5)
        }
        
        return result
    }
    
    /**
     * Creates derived edges if virtual node is selected
     * 
     * Uses getDerived.add(target) if derived edge is a collection
     * Uses setDerived(target) if derived edge is singular
     */
    private def String generateProcessMethods(List<VirtualNode> virtualNodes) {
    val methods = new StringBuilder()
    
    for (vn : virtualNodes) {
            
            methods.append('''
            private void process_«vn.name»(EObject virtualNode) {
                try {
                    «vn.name» vNode = («vn.name») virtualNode;
                    Object source = vNode.get«vn.sourceReference.toFirstUpper»();
                    Object target = vNode.get«vn.targetReference.toFirstUpper»();
                    
                    if (source == null || target == null) {
                        logger.warning("  ERROR: source or target is null");
                        return;
                    }
                    
                    if (vNode.isIsSelected()) {
	                    Method sourceGetter = source.getClass()
	                        .getMethod("get«vn.sourceEdge.toFirstUpper»");
	                    Object sourceEdgeValue = sourceGetter.invoke(source);
	                    
	                    if (sourceEdgeValue instanceof java.util.Collection collection) {
	                        collection.add(target);
	                        logger.info("    Added to source.«vn.sourceEdge»");
	                    } else {
	                    	Method setMethod = null;
	                    	for (Method method : source.getClass().getMethods()) {
	                    		if (method.getName().equals("set«vn.sourceEdge.toFirstUpper»")) {
	                    		setMethod = method;
	                    		break;
	                    		}
	                    	}
	                    		                            
	                    	if (setMethod != null) {
	                    		setMethod.invoke(source, target);
	                    		logger.info("    Set source.«vn.sourceEdge»");
	                    	}
	                    }
	                    
	                    Method targetGetter = target.getClass()
	                        .getMethod("get«vn.targetEdge.toFirstUpper»");
	                    Object targetEdgeValue = targetGetter.invoke(target);
	                    
	                    if (targetEdgeValue instanceof java.util.Collection collection) {
	                        collection.add(source);
	                        logger.info("    Added to target.«vn.targetEdge»");
	                    } else {
	                        Method setMethod = null;
	                        for (Method method : target.getClass().getMethods()) {
				            	if (method.getName().equals("set«vn.targetEdge.toFirstUpper»")) {
	                           		setMethod = method;
	                            	break;
	                        	}
	                    	}
	                            
	                    	if (setMethod != null) {
	                        	setMethod.invoke(target, source);
	                        	logger.info("    Set target.«vn.targetEdge»");
	                    	}
	                    }
                    }
                 
                } catch (Exception e) {
                    logger.warning("  Exception in process_«vn.name»: " + e.getMessage());
                    e.printStackTrace();
                }
            }
            ''')
    }
    
    return methods.toString()
}
    
    /**
     * Load the Ecore metamodel
     */
    private def EPackage loadEcoreMetamodel() throws IOException {
        val ResourceSet resourceSet = new ResourceSetImpl()
        resourceSet.getResourceFactoryRegistry()
            .getExtensionToFactoryMap()
            .put("ecore", new EcoreResourceFactoryImpl())
        
        val String ecorePath = "../ihtcvirtualmetamodel/model/Ihtcvirtualmetamodel.ecore"
        val File ecoreFile = new File(ecorePath)
        
        if (!ecoreFile.exists()) {
            throw new IOException("File not found: " + ecoreFile.getAbsolutePath())
        }
        
        val URI uri = URI.createFileURI(ecoreFile.getAbsolutePath())
        val Resource resource = resourceSet.getResource(uri, true)
        
        return resource.getContents().get(0) as EPackage
    }
}