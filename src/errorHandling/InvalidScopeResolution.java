package errorHandling;

import symbolTable.namespace.DefinesNamespace;

/**
 * Class for creating error messages for invalid scope resolution.
 * 
 * @author kostas
 */
public class InvalidScopeResolution extends ErrorMessage{
    /**
     * The error message.
     */
    String error;
    
    /**
     * Default constructor. Initialized with empty message.
     */
    public InvalidScopeResolution(){
        super("");
    }
    
    /**
     * Set the message given the last valid namespace the name of the invalid scope and line information.
     * 
     * @param last_valid The last valid namespace.
     * @param name The name of the invalid resolution.
     * @param line The line of the error.
     * @param pos  The position in the above line.
     */
    public void setMessage(DefinesNamespace last_valid, String name, int line, int pos){
        error = "line " + line + ":" + pos + "error: '" + name + "' does not name a namespace or a class inside '" + last_valid + "'";
    }

    @Override
    public String getMessage(){
        return this.error;
    }
    
}
