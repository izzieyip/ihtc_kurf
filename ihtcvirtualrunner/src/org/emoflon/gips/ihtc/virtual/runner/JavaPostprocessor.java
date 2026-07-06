package org.emoflon.gips.ihtc.virtual.runner;

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
            if (className.equals("VirtualShiftToWorkload")) {
                process_VirtualShiftToWorkload(obj);
                virtualNodesToDelete.add(obj);
            } else if (className.equals("VirtualShiftToRoster")) {
                process_VirtualShiftToRoster(obj);
                virtualNodesToDelete.add(obj);
            } else if (className.equals("VirtualWorkloadToOpTime")) {
                process_VirtualWorkloadToOpTime(obj);
                virtualNodesToDelete.add(obj);
            } else if (className.equals("VirtualOpTimeToCapacity")) {
                process_VirtualOpTimeToCapacity(obj);
                virtualNodesToDelete.add(obj);
            } else if (className.equals("VirtualWorkloadToCapacity")) {
                process_VirtualWorkloadToCapacity(obj);
                virtualNodesToDelete.add(obj);
            } 
        }
        
        // Remove all virtual nodes
        logger.info("  Deleting virtual nodes...");
        for (EObject virtualNode : virtualNodesToDelete) {
            EcoreUtil.remove(virtualNode);
        }
        logger.info("  Deleted virtual nodes");
    }
    
    private void process_VirtualShiftToWorkload(EObject virtualNode) {
        try {
            VirtualShiftToWorkload vNode = (VirtualShiftToWorkload) virtualNode;
            Object source = vNode.getShift();
            Object target = vNode.getWorkload();
            
            if (source == null || target == null) {
                logger.warning("  ERROR: source or target is null");
                return;
            }
            
            if (vNode.isIsSelected()) {
    	                    Method sourceGetter = source.getClass()
    	                        .getMethod("getDerivedWorkloads");
    	                    Object sourceEdgeValue = sourceGetter.invoke(source);
    	                    
    	                    if (sourceEdgeValue instanceof java.util.Collection collection) {
    	                        collection.add(target);
    	                        logger.info("    Added to source.derivedWorkloads");
    	                    } else {
    	                    	Method setMethod = null;
    	                    	for (Method method : source.getClass().getMethods()) {
    	                    		if (method.getName().equals("setDerivedWorkloads")) {
    	                    		setMethod = method;
    	                    		break;
    	                    		}
    	                    	}
    	                    		                            
    	                    	if (setMethod != null) {
    	                    		setMethod.invoke(source, target);
    	                    		logger.info("    Set source.derivedWorkloads");
    	                    	}
    	                    }
    	                    
    	                    Method targetGetter = target.getClass()
    	                        .getMethod("getDerivedShift");
    	                    Object targetEdgeValue = targetGetter.invoke(target);
    	                    
    	                    if (targetEdgeValue instanceof java.util.Collection collection) {
    	                        collection.add(source);
    	                        logger.info("    Added to target.derivedShift");
    	                    } else {
    	                        Method setMethod = null;
    	                        for (Method method : target.getClass().getMethods()) {
    				            	if (method.getName().equals("setDerivedShift")) {
    	                           		setMethod = method;
    	                            	break;
    	                        	}
    	                    	}
    	                            
    	                    	if (setMethod != null) {
    	                        	setMethod.invoke(target, source);
    	                        	logger.info("    Set target.derivedShift");
    	                    	}
    	                    }
            }
         
        } catch (Exception e) {
            logger.warning("  Exception in process_VirtualShiftToWorkload: " + e.getMessage());
            e.printStackTrace();
        }
    }
    private void process_VirtualShiftToRoster(EObject virtualNode) {
        try {
            VirtualShiftToRoster vNode = (VirtualShiftToRoster) virtualNode;
            Object source = vNode.getShift();
            Object target = vNode.getRoster();
            
            if (source == null || target == null) {
                logger.warning("  ERROR: source or target is null");
                return;
            }
            
            if (vNode.isIsSelected()) {
    	                    Method sourceGetter = source.getClass()
    	                        .getMethod("getDerivedRoster");
    	                    Object sourceEdgeValue = sourceGetter.invoke(source);
    	                    
    	                    if (sourceEdgeValue instanceof java.util.Collection collection) {
    	                        collection.add(target);
    	                        logger.info("    Added to source.derivedRoster");
    	                    } else {
    	                    	Method setMethod = null;
    	                    	for (Method method : source.getClass().getMethods()) {
    	                    		if (method.getName().equals("setDerivedRoster")) {
    	                    		setMethod = method;
    	                    		break;
    	                    		}
    	                    	}
    	                    		                            
    	                    	if (setMethod != null) {
    	                    		setMethod.invoke(source, target);
    	                    		logger.info("    Set source.derivedRoster");
    	                    	}
    	                    }
    	                    
    	                    Method targetGetter = target.getClass()
    	                        .getMethod("getDerivedShifts");
    	                    Object targetEdgeValue = targetGetter.invoke(target);
    	                    
    	                    if (targetEdgeValue instanceof java.util.Collection collection) {
    	                        collection.add(source);
    	                        logger.info("    Added to target.derivedShifts");
    	                    } else {
    	                        Method setMethod = null;
    	                        for (Method method : target.getClass().getMethods()) {
    				            	if (method.getName().equals("setDerivedShifts")) {
    	                           		setMethod = method;
    	                            	break;
    	                        	}
    	                    	}
    	                            
    	                    	if (setMethod != null) {
    	                        	setMethod.invoke(target, source);
    	                        	logger.info("    Set target.derivedShifts");
    	                    	}
    	                    }
            }
         
        } catch (Exception e) {
            logger.warning("  Exception in process_VirtualShiftToRoster: " + e.getMessage());
            e.printStackTrace();
        }
    }
    private void process_VirtualWorkloadToOpTime(EObject virtualNode) {
        try {
            VirtualWorkloadToOpTime vNode = (VirtualWorkloadToOpTime) virtualNode;
            Object source = vNode.getWorkload();
            Object target = vNode.getOpTime();
            
            if (source == null || target == null) {
                logger.warning("  ERROR: source or target is null");
                return;
            }
            
            if (vNode.isIsSelected()) {
    	                    Method sourceGetter = source.getClass()
    	                        .getMethod("getDerivedOpTimes");
    	                    Object sourceEdgeValue = sourceGetter.invoke(source);
    	                    
    	                    if (sourceEdgeValue instanceof java.util.Collection collection) {
    	                        collection.add(target);
    	                        logger.info("    Added to source.derivedOpTimes");
    	                    } else {
    	                    	Method setMethod = null;
    	                    	for (Method method : source.getClass().getMethods()) {
    	                    		if (method.getName().equals("setDerivedOpTimes")) {
    	                    		setMethod = method;
    	                    		break;
    	                    		}
    	                    	}
    	                    		                            
    	                    	if (setMethod != null) {
    	                    		setMethod.invoke(source, target);
    	                    		logger.info("    Set source.derivedOpTimes");
    	                    	}
    	                    }
    	                    
    	                    Method targetGetter = target.getClass()
    	                        .getMethod("getDerivedWorkloads");
    	                    Object targetEdgeValue = targetGetter.invoke(target);
    	                    
    	                    if (targetEdgeValue instanceof java.util.Collection collection) {
    	                        collection.add(source);
    	                        logger.info("    Added to target.derivedWorkloads");
    	                    } else {
    	                        Method setMethod = null;
    	                        for (Method method : target.getClass().getMethods()) {
    				            	if (method.getName().equals("setDerivedWorkloads")) {
    	                           		setMethod = method;
    	                            	break;
    	                        	}
    	                    	}
    	                            
    	                    	if (setMethod != null) {
    	                        	setMethod.invoke(target, source);
    	                        	logger.info("    Set target.derivedWorkloads");
    	                    	}
    	                    }
            }
         
        } catch (Exception e) {
            logger.warning("  Exception in process_VirtualWorkloadToOpTime: " + e.getMessage());
            e.printStackTrace();
        }
    }
    private void process_VirtualOpTimeToCapacity(EObject virtualNode) {
        try {
            VirtualOpTimeToCapacity vNode = (VirtualOpTimeToCapacity) virtualNode;
            Object source = vNode.getOpTime();
            Object target = vNode.getCapacity();
            
            if (source == null || target == null) {
                logger.warning("  ERROR: source or target is null");
                return;
            }
            
            if (vNode.isIsSelected()) {
    	                    Method sourceGetter = source.getClass()
    	                        .getMethod("getDerivedCapacities");
    	                    Object sourceEdgeValue = sourceGetter.invoke(source);
    	                    
    	                    if (sourceEdgeValue instanceof java.util.Collection collection) {
    	                        collection.add(target);
    	                        logger.info("    Added to source.derivedCapacities");
    	                    } else {
    	                    	Method setMethod = null;
    	                    	for (Method method : source.getClass().getMethods()) {
    	                    		if (method.getName().equals("setDerivedCapacities")) {
    	                    		setMethod = method;
    	                    		break;
    	                    		}
    	                    	}
    	                    		                            
    	                    	if (setMethod != null) {
    	                    		setMethod.invoke(source, target);
    	                    		logger.info("    Set source.derivedCapacities");
    	                    	}
    	                    }
    	                    
    	                    Method targetGetter = target.getClass()
    	                        .getMethod("getDerivedOpTimes");
    	                    Object targetEdgeValue = targetGetter.invoke(target);
    	                    
    	                    if (targetEdgeValue instanceof java.util.Collection collection) {
    	                        collection.add(source);
    	                        logger.info("    Added to target.derivedOpTimes");
    	                    } else {
    	                        Method setMethod = null;
    	                        for (Method method : target.getClass().getMethods()) {
    				            	if (method.getName().equals("setDerivedOpTimes")) {
    	                           		setMethod = method;
    	                            	break;
    	                        	}
    	                    	}
    	                            
    	                    	if (setMethod != null) {
    	                        	setMethod.invoke(target, source);
    	                        	logger.info("    Set target.derivedOpTimes");
    	                    	}
    	                    }
            }
         
        } catch (Exception e) {
            logger.warning("  Exception in process_VirtualOpTimeToCapacity: " + e.getMessage());
            e.printStackTrace();
        }
    }
    private void process_VirtualWorkloadToCapacity(EObject virtualNode) {
        try {
            VirtualWorkloadToCapacity vNode = (VirtualWorkloadToCapacity) virtualNode;
            Object source = vNode.getWorkload();
            Object target = vNode.getCapacity();
            
            if (source == null || target == null) {
                logger.warning("  ERROR: source or target is null");
                return;
            }
            
            if (vNode.isIsSelected()) {
    	                    Method sourceGetter = source.getClass()
    	                        .getMethod("getDerivedCapacity");
    	                    Object sourceEdgeValue = sourceGetter.invoke(source);
    	                    
    	                    if (sourceEdgeValue instanceof java.util.Collection collection) {
    	                        collection.add(target);
    	                        logger.info("    Added to source.derivedCapacity");
    	                    } else {
    	                    	Method setMethod = null;
    	                    	for (Method method : source.getClass().getMethods()) {
    	                    		if (method.getName().equals("setDerivedCapacity")) {
    	                    		setMethod = method;
    	                    		break;
    	                    		}
    	                    	}
    	                    		                            
    	                    	if (setMethod != null) {
    	                    		setMethod.invoke(source, target);
    	                    		logger.info("    Set source.derivedCapacity");
    	                    	}
    	                    }
    	                    
    	                    Method targetGetter = target.getClass()
    	                        .getMethod("getDerivedWorkloads");
    	                    Object targetEdgeValue = targetGetter.invoke(target);
    	                    
    	                    if (targetEdgeValue instanceof java.util.Collection collection) {
    	                        collection.add(source);
    	                        logger.info("    Added to target.derivedWorkloads");
    	                    } else {
    	                        Method setMethod = null;
    	                        for (Method method : target.getClass().getMethods()) {
    				            	if (method.getName().equals("setDerivedWorkloads")) {
    	                           		setMethod = method;
    	                            	break;
    	                        	}
    	                    	}
    	                            
    	                    	if (setMethod != null) {
    	                        	setMethod.invoke(target, source);
    	                        	logger.info("    Set target.derivedWorkloads");
    	                    	}
    	                    }
            }
         
        } catch (Exception e) {
            logger.warning("  Exception in process_VirtualWorkloadToCapacity: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
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
