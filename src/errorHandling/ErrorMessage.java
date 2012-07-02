/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

/**
 *
 * @author kostas
 */
public class ErrorMessage {
    
    private String msg;
    
    public ErrorMessage(String msg){
        this.msg = msg;
    }
    
    public String getError(){
        return this.msg;
    }
}
