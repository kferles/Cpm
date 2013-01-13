package errorHandling;

import symbolTable.namespace.TypeDefinition;
import symbolTable.types.Type;

/**
 * Class for creating error messages when a new element changes the meaning of a visible non ambiguous type name.
 * 
 * @author kostas
 */
public class ChangingMeaningOf extends ErrorMessage {
    
    /**
     * Holds message's last line.
     */
    private String final_err = null;
    
    /**
     * Creates an instance given the identifier that creates the conflict and the full name of the type.
     * 
     * @param id The identifier that rises the conflict.
     * @param name The name of the type that is being shadowed.
     * @param field The type information of the field that rises the conflict.
     * @param type The type definition information that is being shadowed.
     * @param line The line for the error.
     * @param pos  The position in the above line.
     */
    public ChangingMeaningOf(String id, String name, Type field, TypeDefinition type, int line, int pos){
        super("line " + line + ":" + pos + " error: declaration of '" + field.toString(id) + '\'');
        final_err = type.getFileName() + " line " + type.getLine() + ":" + type.getPosition() + " error: changes meaning of '" + name + "' from '" + type + '\'';
    }
    
    /**
     * Returns message's last line.
     * 
     * @return The text for the conflicted declaration.
     */
    public String getFinalError(){
        return this.final_err;
    }
    
}
