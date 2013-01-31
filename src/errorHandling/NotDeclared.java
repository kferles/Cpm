package errorHandling;

/**
 * Class for creating an error message when the parser tries to find a symbol
 * that is not declared.
 * 
 * @author kostas
 */
public class NotDeclared extends ErrorMessage{
    
    /**
     * Constructs an object given the name of the symbol, its line and the position in the line.
     * 
     * @param symbolName The identifier from the user input.
     * @param line The line that contains the identifier.
     * @param pos  And the position inside the line.
     */
    public NotDeclared(String symbolName, int line, int pos){
        super("line" + line + ":" + pos + " error: '" + symbolName +"' has not been declared");
    }


}
