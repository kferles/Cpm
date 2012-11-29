/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

import symbolTable.namespace.TypeDefinition;

/**
 *
 * @author kostas
 */
public class BaseClassCVQual extends ErrorMessage{
    
    public BaseClassCVQual(TypeDefinition t){
        super("error: base class '" + t.toString() +"' has cv qualifiers");
    }
    
}
