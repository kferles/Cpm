/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

/**
 *
 * @author kostas
 */
public class DoesNotNameType extends ErrorMessage{
    
    public DoesNotNameType(String symbolName){
        super("error: '"+ symbolName +"' does not name a type");
    }
    
}
