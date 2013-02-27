package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class TypeNameToken extends CommonToken {
    
    private String id;
    
    private Type t;
    
    public TypeNameToken(int tNode, String id, Type t){
        super(tNode, "TYPE_NAME");
        this.id = id;
        this.t = t;
    }
    
    public String getId(){
        return this.id;
    }
    
    public Type get_type(){
        return this.t;
    }
    
}
