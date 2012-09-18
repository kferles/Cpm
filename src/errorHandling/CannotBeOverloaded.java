/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

import symbolTable.types.Method;

/**
 *
 * @author kostas
 */
public class CannotBeOverloaded extends ErrorMessage{
    
    String final_err = null;
    
    public CannotBeOverloaded(String name, Method new_m, Method old_m, int new_line, int new_pos, String olds_fileName, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: '" + new_m.toString(name) + "' cannot be overloaded");
        this.final_err = olds_fileName + " line " + old_line + ":" + old_pos + " error: with '" + old_m.toString(name) + "'";
    }
    
    public String getFinalError(){
        return this.final_err;
    }
    
}
