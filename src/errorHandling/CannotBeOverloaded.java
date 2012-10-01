/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

/**
 *
 * @author kostas
 */
public class CannotBeOverloaded extends ErrorMessage{
    
    String final_err = null;
    
    public CannotBeOverloaded(String new_m, String old_m, int new_line, int new_pos, String olds_fileName, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: '" + new_m + "' cannot be overloaded");
        this.final_err = olds_fileName + " line " + old_line + ":" + old_pos + " error: with '" + old_m + "'";
    }
    
    public String getFinalError(){
        return this.final_err;
    }
    
}
