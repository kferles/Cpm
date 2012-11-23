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
public class InvalidScopeResolution extends ErrorMessage{
    
    String error;
    
    public InvalidScopeResolution(){
        super("");
    }
    
    public void setMessage(DefinesNamespace last_valid, String name, int line, int pos){
        error = "line " + line + ":" + pos + "error: '" + name + "' does not name a namespace or a class inside '" + last_valid + "'";
    }

    @Override
    public String getMessage(){
        return this.error;
    }
    
}
