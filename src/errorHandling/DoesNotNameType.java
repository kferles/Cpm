package errorHandling;

/**
 * Class for creating error message when an identifier does not name a type.
 * 
 * @author kostas
 */
public class DoesNotNameType extends ErrorMessage{
    
    /**
     * Creates an instance given the identifier.
     * 
     * @param symbolName The identifier.
     */
    public DoesNotNameType(String symbolName){
        super("error: '"+ symbolName +"' does not name a type");
    }
    
}
