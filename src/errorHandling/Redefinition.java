package errorHandling;

import symbolTable.namespace.TypeDefinition;
import symbolTable.types.Type;

/**
 * Class for creating error messages when a symbol is redefined inside a namespace as a different symbol.
 * C+- in contrast with C++ does not allow double declarations inside a class (which actually defines a namespace), 
 * so the same message is printed for classes.
 *
 * @author kostas
 */
public class Redefinition extends ErrorMessage{
    
    /**
     * The last line of the message.
     */
    private String final_err = null;
    
    /**
     * Constructs and object given the first and the last entry that raise the conflict.
     * 
     * @param new_entry The type information for the last entry.
     * @param old_entry The type information for the first entry.
     */
    public Redefinition(TypeDefinition new_entry, TypeDefinition old_entry){
        super("line " + new_entry.getLine() + ":" + new_entry.getPosition() + " error: redefinition of '" + new_entry + "'" );
        this.final_err = old_entry.getFileName() + " line " + old_entry.getLine() + ":" + old_entry.getPosition() + " error: previous definition of '" + old_entry + "'";
    }
    
    public Redefinition(String name, Type new_m, int new_line, int new_pos, Type old_m, String old_filename, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: redefinition of '" + new_m.toString(name) + "'");
        this.final_err = old_filename + " line " + old_line + ":" + old_pos + " error: previous definition of '" + old_m.toString(name) + "'";
    }
    
    /**
     * Returns error message's last line.
     * 
     * @return The text for the last line.
     */
    public String getFinalError(){
        return this.final_err;
    }
    
}
