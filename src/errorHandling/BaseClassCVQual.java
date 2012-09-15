/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

import symbolTable.namespace.NamedType;

/**
 *
 * @author kostas
 */
public class BaseClassCVQual extends ErrorMessage{
    
    public BaseClassCVQual(NamedType t){
        super("error: base class '" + t.toString() +"' has cv qualifiers");
    }
    
}
