/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

import symbolTable.namespace.NamedType;
import symbolTable.namespace.Namespace;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class DiffrentSymbol extends ErrorMessage{
    
    private String final_err = null;
    
    public DiffrentSymbol(String name, Type new_entry, Namespace old_entry, int new_line, int new_pos, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: '" + new_entry.toString(name) + "' redeclared as different kind of symbol");
        this.final_err = old_entry.getFileName() + " line " + old_line + ":" + old_pos + " error: previous declaration of '" + old_entry + "'";
    }
    
    public DiffrentSymbol(String name, NamedType new_entry, Namespace old_entry, int new_line, int new_pos, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: '" + new_entry + "' redeclared as different kind of symbol");
        this.final_err = old_entry.getFileName() + " line " + old_line + ":" + old_pos + " error: previous declaration of '" + old_entry + "'";
    }
    
    public DiffrentSymbol(String name, Namespace new_entry, Type old_entry, int new_line, int new_pos, String oldFileName, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: '" + new_entry + "' redeclared as different kind of symbol");
        this.final_err = oldFileName + " line " + old_line + ":" + old_pos + " error: previous declaration of '" + old_entry.toString(name) + "'";
    }
    
    public DiffrentSymbol(String name, Namespace new_entry, NamedType old_entry, int new_line, int new_pos, int old_line, int old_pos){
        super("line " + new_line + ":" + new_pos + " error: '" + new_entry + "' redeclared as different kind of symbol");
        this.final_err = old_entry.getFileName() + " line " + old_line + ":" + old_pos + " error: previous declaration of '" + old_entry + "'";
    }
    
    public String getFinalError(){
        return this.final_err;
    }
    
}
