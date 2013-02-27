package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class DeclarationToken extends CommonToken{
    
    Type declType;
    
    public DeclarationToken(int tNode, Type declType){
        super(tNode, "DECLARATION");
        this.declType = declType;
    }
    
    public Type getDeclType(){
        return this.declType;
    }
    
}
