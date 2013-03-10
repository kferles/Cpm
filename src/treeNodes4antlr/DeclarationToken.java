package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class DeclarationToken extends CommonToken{

    private Type declType;

    private boolean isMethod;

    public DeclarationToken(int tNode, Type declType, boolean isMethod){
        super(tNode, "DECLARATION");
        this.declType = declType;
        this.isMethod = isMethod;
    }

    public Type getDeclType(){
        return this.declType;
    }

    public boolean getIsMethod(){
        return this.isMethod;
    }

}
