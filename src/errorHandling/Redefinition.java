/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

import symbolTable.namespace.TypeDefinition;
import symbolTable.types.Method;

/**
 *
 * @author kostas
 */
public class Redefinition extends ErrorMessage{
    
    private String final_err = null;
    
    public Redefinition(TypeDefinition new_entry, TypeDefinition old_entry){
        super("line " + new_entry.getLine() + ":" + new_entry.getPosition() + " error: redefinition of '" + new_entry + "'" );
        this.final_err = old_entry.getFileName() + " line " + old_entry.getLine() + ":" + old_entry.getPosition() + " error: previous definition of '" + old_entry + "'";
    }
    
    public Redefinition(String name, Method new_m, int new_line, int new_pos, Method old_m, String old_filename, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: redefinition of '" + new_m.toString(name) + "'");
        this.final_err = old_filename + " line " + old_line + ":" + old_pos + " error: previous definition of '" + old_m.toString(name);
    }
    
    public String getFinalError(){
        return this.final_err;
    }
    
}
