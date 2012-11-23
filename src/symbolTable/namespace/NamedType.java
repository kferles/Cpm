/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package symbolTable.namespace;

import errorHandling.BaseClassCVQual;
import errorHandling.VoidDeclaration;

/**
 *
 * @author kostas
 */
public interface NamedType {
    
    String getFullName();
    
    String getName();
    
    String getTag();
    
    int getLine();
    
    int getPosition();
    
    CpmClass isClassName() throws BaseClassCVQual;
    
    DefinesNamespace getParentNamespace();
    
    boolean isComplete(CpmClass current) throws VoidDeclaration;
    
    String getFileName();
    
}
