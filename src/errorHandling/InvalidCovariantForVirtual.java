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
public class InvalidCovariantForVirtual extends ErrorMessage {
    
    String message;
    String final_error;
    String fileName;
    
    public InvalidCovariantForVirtual(String name, Method derived, Method base, String baseFileName){
        super("error: invalid covariant return type for 'virtual " + derived.toString(ErrorMessage.getFullName(derived, name)) + "'");
        this.final_error = "error: overriding '" + base.toString(ErrorMessage.getFullName(base, name)) + "'";
        this.fileName = baseFileName;
    }
    
    public String getMessage(int der_line, int der_pos){
        return "line " + der_line + ":" + der_pos + " " + this.getMessage();
    }
    
    public String getFinalError(){
        return this.final_error;
    }
    
    public void setLineAndPos(int base_line, int base_pos){
        this.final_error = this.fileName + " line " + base_line + ":" + base_pos + " " + this.final_error;
    }
    
}
