package errorHandling;

/**
 *
 * @author kostas
 */
public class InvalidMethodLocalDeclaration extends ErrorMessage {
    
    public InvalidMethodLocalDeclaration(String declarationType){
        super("error: C+- forbids " + declarationType + " as method declarations");
    }
    
}
