/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

/**
 *
 * @author kostas
 */
public class VoidDeclaration extends ErrorMessage {
    
    public VoidDeclaration(){
        super("");
    }
    
    public String getMessage(String name){
        return "error: variable or field '" + name + "' declared void";
    }
    
}
