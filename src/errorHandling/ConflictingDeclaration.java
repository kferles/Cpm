package errorHandling;

import symbolTable.namespace.TypeDefinition;
import symbolTable.types.Type;

/**
 * Class for creating error messages when two declaration conflict in the same scope.
 * 
 * @author kostas
 */
public class ConflictingDeclaration extends ErrorMessage{
    
    /**
     * Error message's last line.
     */
    private String final_err = null;
    
    /**
     * Creates an instance when two fields have a name conflict.
     * 
     * @param name The name that rises the conflict.
     * @param new_entry The type information of the last declaration in the file.
     * @param old_entry The type information of the previous declaration.
     * @param new_line The line of the last declaration in the file.
     * @param new_pos The position in the above line.
     * @param oldsFileName The file that contains the previous declaration.
     * @param old_line The line of the old declaration.
     * @param old_pos  The position in the above line.
     */
    public ConflictingDeclaration(String name, Type new_entry, Type old_entry, int new_line, int new_pos, String oldsFileName, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: declaration of: '" + new_entry.toString(name) + "'");
        this.final_err = oldsFileName + " line " + old_line + ":" + old_pos + " error: conflicts with previous declaration '" + old_entry.toString(name) + "'";
    }
    
    /**
     * Creates an instance when a fields and a type name have a name conflict.
     * 
     * @param name The name that rises the conflict.
     * @param new_entry The type information for the type definition.
     * @param old_entry The type information of the previous declaration.
     * @param new_line The line of the type definition in the file.
     * @param new_pos The position in the above line.
     * @param oldsFileName The file that contains the previous declaration.
     * @param old_line The line of the old declaration.
     * @param old_pos  The position in the above line.
     */
    public ConflictingDeclaration(String name, TypeDefinition new_entry, Type old_entry, int new_line, int new_pos, String oldsFileName, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: declaration of: '" + new_entry + "'");
        this.final_err = oldsFileName + " line " + old_line + ":" + old_pos + " error: conflicts with previous declaration '" + old_entry.toString(name) + "'";
    }
    
    /**
     * Returns error message's last line.
     * 
     * @return The text for the above message.
     */
    public String getFinalError(){
        return this.final_err;
    }
    
}
