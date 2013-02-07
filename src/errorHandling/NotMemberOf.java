package errorHandling;

import symbolTable.namespace.DefinesNamespace;

/**
 * Class for creating error messages when the parser tries to recognize a nested identifier (i.e., A::B)
 * and fails to detect a member of a namespace.
 * 
 * @author kostas
 */
public class NotMemberOf extends ErrorMessage {
    
    /**
     * Constructs an object given the undefined symbol, the namespace that the lookup is performed and the
     * appropriate line information.
     * 
     * @param symbolName The name of the undefined symbol.
     * @param namespace The namespace that the lookup is performed.
     * @param line The line of the lookup.
     * @param pos  The position in the above line.
     */
    public NotMemberOf(String symbolName, DefinesNamespace namespace, int line, int pos){
        super("line " + line + ":" + pos + " error: '" + symbolName + "' is not a member of '" + namespace + "'");
    }
    
}
