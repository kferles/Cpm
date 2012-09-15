/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

import symbolTable.namespace.DefinesNamespace;

/**
 *
 * @author kostas
 */
public class NotMemberOf extends ErrorMessage {
    
    public NotMemberOf(String symbolName, DefinesNamespace namespace, int line, int pos){
        super("line " + line + ":" + pos + " error: '" + symbolName + "' is not a member of '" + namespace + "'");
    }
    
}
