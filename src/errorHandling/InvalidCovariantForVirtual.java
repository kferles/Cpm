package errorHandling;

import symbolTable.types.Method;

/**
 * Class for creating error messages when a derived virtual method does not
 * have a covariant return type.
 * 
 * @author kostas
 */
public class InvalidCovariantForVirtual extends ErrorMessage {
    
    /**
     * Error message's last line.
     */
    String final_error;
    
    /**
     * The filename that contains base class' definition.
     */
    String fileName;
    
    /**
     * Creates an instance given the name of the methods and the signatures for both derived and base method.
     * 
     * @param name Method's name.
     * @param derived Derived method's signature.
     * @param base Base method's signature.
     * @param baseFileName  File name that contains the Base class.
     */
    public InvalidCovariantForVirtual(String name, Method derived, Method base, String baseFileName){
        super("error: invalid covariant return type for 'virtual " + derived.toString(ErrorMessage.getFullName(derived, name)) + "'");
        this.final_error = "error: overriding '" + base.toString(ErrorMessage.getFullName(base, name)) + "'";
        this.fileName = baseFileName;
    }
    
    /**
     * Returns error message.
     * 
     * @param der_line message's line.
     * @param der_pos the position in the above line.
     * @return  Message's string representation.
     */
    public String getMessage(int der_line, int der_pos){
        return "line " + der_line + ":" + der_pos + " " + this.getMessage();
    }
    
    /**
     * Returns message's last line.
     * @return 
     */
    public String getFinalError(){
        return this.final_error;
    }
    
    /**
     * Set line and position for the message (the part referring to the base method)
     * @param base_line base method's line.
     * @param base_pos  position in the above line.
     */
    public void setLineAndPos(int base_line, int base_pos){
        this.final_error = this.fileName + " line " + base_line + ":" + base_pos + " " + this.final_error;
    }
    
}
