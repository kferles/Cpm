package errorHandling;

import symbolTable.types.Method;

/**
 * Class for creating error messages when a derived class tries to override a virtual method
 * and there is a conflict in the return value.
 * 
 * @author kostas
 */
public class ConflictingRVforVirtual extends ErrorMessage{
    
    /**
     * Error message's last line.
     */
    String final_error;
    
    /**
     * The filename that the base class belongs to.
     */
    String fileName;
    
    /**
     * Creates an instance given the name of the method and the information about the signatures.
     * 
     * @param name The name of both methods.
     * @param der Derived method's signature information.
     * @param base Base method's signature information.
     * @param baseFileName  The filename that the base class belongs to.
     */
    public ConflictingRVforVirtual(String name, Method der, Method base, String baseFileName){
        super("error: conflicting return type specified for 'virtual " + der.toString(ErrorMessage.getFullName(der, name)) + "'");
        this.final_error = "error: overriding '" + base.toString(ErrorMessage.getFullName(base, name)) +"'";
        this.fileName = baseFileName;
    }
    
    /**
     * Returns the message augmented with line and position information.
     * 
     * @param der_line Derived method's line.
     * @param der_pos The position in the above line.
     * @return The error message.
     */
    public String getMessage(int der_line, int der_pos){
        return "line " + der_line + ":" + der_pos + " " + this.getMessage();
    }
    
    /**
     * Returns error message's last line.
     * @return The text for the last line.
     */
    public String getFinalError(){
        return this.final_error;
    }
    
    /**
     * Set line and position for error message's last line.
     * 
     * @param base_line Based method's line.
     * @param base_pos  The position in the above line.
     */
    public void setLineAndPos(int base_line, int base_pos){
        this.final_error = fileName + "line " + base_line + ":" + base_pos + " " + this.final_error;
    }

}
