package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class NewTypeIdToken extends CommonToken {
    
    private final Type t;
    
    public NewTypeIdToken(int tNode, Type t){
        super(tNode, "NEW_TYPE_ID");
        this.t = t;
    }
    
    public Type get_type(){
        return this.t;
    }
}
