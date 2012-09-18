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
public class Redefinition extends ErrorMessage{
    
    private String final_err = null;
    
    public Redefinition(NamedType new_entry, NamedType old_entry){
        super("line " + new_entry.getLine() + ":" + new_entry.getPosition() + " error: redefinition of '" + new_entry + "'" );
        this.final_err = old_entry.getFileName() + " line " + old_entry.getLine() + ":" + old_entry.getPosition() + " error: previous definition of '" + old_entry + "'";
    }
    
    public String getFinalError(){
        return this.final_err;
    }
    
}
