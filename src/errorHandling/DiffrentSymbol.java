package errorHandling;

import symbolTable.namespace.Namespace;
import symbolTable.namespace.TypeDefinition;
import symbolTable.types.Type;
/*
 * TODO: refactor (only one constructor) 
 */
/**
 * Class for creating error messages when inside a namespace there are two declarations 
 * with the same name.
 * 
 * @author kostas
 */
public class DiffrentSymbol extends ErrorMessage{
    
    /**
     * Last line of the message.
     */
    private String final_err = null;
    
    /**
     * Creates an instance when there is conflict between a field and a namespace.
     * 
     * @param name The name that rises the conflict.
     * @param new_entry The field.
     * @param old_entry The namespace.
     * @param new_line The line of the field.
     * @param new_pos The position in the above line.
     * @param old_line The line of the namespace.
     * @param old_pos  The position in the above line.
     */
    public DiffrentSymbol(String name, Type new_entry, Namespace old_entry, int new_line, int new_pos, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: '" + new_entry.toString(name) + "' redeclared as different kind of symbol");
        this.final_err = old_entry.getFileName() + " line " + old_line + ":" + old_pos + " error: previous declaration of '" + old_entry + "'";
    }
    
    public DiffrentSymbol(String name, TypeDefinition new_entry, Namespace old_entry, int new_line, int new_pos, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: '" + new_entry + "' redeclared as different kind of symbol");
        this.final_err = old_entry.getFileName() + " line " + old_line + ":" + old_pos + " error: previous declaration of '" + old_entry + "'";
    }
    
    /**
     * Creates an instance when there is conflict between a field and a namespace.
     * 
     * @param name The name that rises the conflict.
     * @param new_entry The field.
     * @param old_entry The namespace.
     * @param new_line The line of the field.
     * @param new_pos The position in the above line.
     * @param old_line The line of the namespace.
     * @param old_pos  The position in the above line.
     */
    public DiffrentSymbol(String name, Namespace new_entry, Type old_entry, int new_line, int new_pos, String oldFileName, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: '" + new_entry + "' redeclared as different kind of symbol");
        this.final_err = oldFileName + " line " + old_line + ":" + old_pos + " error: previous declaration of '" + old_entry.toString(name) + "'";
    }
    
    public DiffrentSymbol(String name, Namespace new_entry, TypeDefinition old_entry, int new_line, int new_pos, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: '" + new_entry + "' redeclared as different kind of symbol");
        this.final_err = old_entry.getFileName() + " line " + old_line + ":" + old_pos + " error: previous declaration of '" + old_entry + "'";
    }
    
    /**
     * Returns the last line of the message.
     * @return  The text for the last line.
     */
    public String getFinalError(){
        return this.final_err;
    }
    
}
