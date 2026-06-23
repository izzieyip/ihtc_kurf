package ihtcvirtualpostprocessing;

import java.io.File;
import java.io.IOException;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl;

public class GTRuleAutomator {

    public static void main(String[] args) throws IOException {
        EPackage metamodel = loadEcoreMetamodel();
        
        System.out.println("Metamodel loaded: " + metamodel.getName());
        System.out.println("Number of classes: " + metamodel.getEClassifiers().size());
        
        for (Object obj : metamodel.getEClassifiers().toArray()) {
        	System.out.println(obj.toString());
        }
        
        // TODO: Generate GT rules
    }

    private static EPackage loadEcoreMetamodel() throws IOException {
        ResourceSet resourceSet = new ResourceSetImpl();
        resourceSet.getResourceFactoryRegistry()
            .getExtensionToFactoryMap()
            .put("ecore", new EcoreResourceFactoryImpl());
        
        String ecorePath = "../ihtcvirtualmetamodel/model/Ihtcvirtualmetamodel.ecore";
        File ecoreFile = new File(ecorePath);
        
        if (!ecoreFile.exists()) {
            throw new IOException("File not found: " + ecoreFile.getAbsolutePath());
        }
        
        URI uri = URI.createFileURI(ecoreFile.getAbsolutePath());
        Resource resource = resourceSet.getResource(uri, true);
        
        return (EPackage) resource.getContents().get(0);
    }
}