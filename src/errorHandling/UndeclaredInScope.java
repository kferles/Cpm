package errorHandling;

/**
 * Unused class for now :P
 * @author kostas
 */
public class UndeclaredInScope extends ErrorMessage{
    
    public UndeclaredInScope(String symbolName){
        super("error: '"+ symbolName +"' was not declared in this scope");
    }
    
}
