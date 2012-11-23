/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

import symbolTable.namespace.NamedType;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class ConflictingDeclaration extends ErrorMessage{
    
    
    private String final_err = null;
    
    public ConflictingDeclaration(String name, Type new_entry, Type old_entry, int new_line, int new_pos, String oldsFileName, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: declaration of: '" + new_entry.toString(name) + "'");
        this.final_err = oldsFileName + " line " + old_line + ":" + old_pos + " error: conflicts with previous declaration '" + old_entry.toString(name) + "'";
    }
    
    public ConflictingDeclaration(String name, NamedType new_entry, Type old_entry, int new_line, int new_pos, String oldsFileName, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: declaration of: '" + new_entry + "'");
        this.final_err = oldsFileName + " line " + old_line + ":" + old_pos + " error: conflicts with previous declaration '" + old_entry.toString(name) + "'";
    }
    
    public String getFinalError(){
        return this.final_err;
    }
    
}
