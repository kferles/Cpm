/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package errorHandling;

import symbolTable.namespace.TypeDefinition;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class ChangingMeaningOf extends ErrorMessage {
    
    private String final_err = null;
    
    public ChangingMeaningOf(String id, String name, Type field, TypeDefinition type, int line, int pos){
        super("line " + line + ":" + pos + " error: declaration of '" + field.toString(id) + '\'');
        final_err = type.getFileName() + " line " + type.getLine() + ":" + type.getPosition() + " error: changes meaning of '" + name + "' from '" + type + '\'';
    }
    
    public String getFinalError(){
        return this.final_err;
    }
    
}
