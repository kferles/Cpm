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
public class SameNameAsParentClass extends ErrorMessage{
    
    public SameNameAsParentClass(NamedType t){
        super("line " + t.getLine() + ":" + t.getPosition() + " error: '" + t.toString() + "' has the same name as the class in which it is declared");
    }
    
}
