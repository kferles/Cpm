package errorHandling;

/**
 * Class for creating error messages when a field is declared to have void type.
 * 
 * @author kostas
 */
public class VoidDeclaration extends ErrorMessage {
    
    /**
     * Default dummy constructor.
     */
    public VoidDeclaration(){
        super("");
    }
    
    /**
     * Returns the actual error message given the name of the field.
     * 
     * @param name Field 's name.
     * @return The error message for the user.
     */
    public String getMessage(String name){
        return "error: variable or field '" + name + "' declared void";
    }
    
}
