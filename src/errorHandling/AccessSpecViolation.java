package errorHandling;

/**
 * Class for creating error messages when there is an
 * access violation (e.g. access to something private through
 * a non friend scope).
 * @author kostas
 */
public class AccessSpecViolation extends ErrorMessage{

    /*
     * Text to complete the error message.
     * For example:
     * file in line:pos error: 'i' is private
     * file in line:pos error:  whithin this context //use point
     */
    String context_err = "error: whithin this context";
    
    /**
     * Creates an AccessSpecViolation instance given a message.
     * 
     * @param msg The text for the error message. It should something like:
     * "error: 'field' is private/protected"
     */
    public AccessSpecViolation (String msg){
        super(msg);
    }
    
    /**
     * Method to set the line and the character position for the context error.
     * 
     * @param line The line where is the access specifier violation.
     * @param pos  The character position in the above line.
     */
    public void setContextError(int line, int pos){
        this.context_err = "line " + line + ":" + pos + " " + this.context_err;
    }
    
    /**
     * Returns context error message.
     * 
     * @return The context error.
     */
    public String getContextError(){
        return this.context_err;
    }
    
}
