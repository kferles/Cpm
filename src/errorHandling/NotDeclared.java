package errorHandling;

/**
 *
 * @author kostas
 */
public class NotDeclared extends ErrorMessage{
    
    
    public NotDeclared(String symbolName, int line, int pos){
        super("line" + line + ":" + pos + " error: '" + symbolName +"' has not been declared");
    }


}
