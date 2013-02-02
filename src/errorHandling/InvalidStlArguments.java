/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

/**
 *
 * @author kostas
 */
public class InvalidStlArguments extends ErrorMessage{
    
    private String final_err;

    public InvalidStlArguments(String container_name, String err){
        super("error: invalid arguments for " + container_name + "container");
        this.final_err = err;
    }
    
    public String getFinalErr(){
        return this.final_err;
    }

}
