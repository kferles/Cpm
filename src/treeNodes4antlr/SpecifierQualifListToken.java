package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class SpecifierQualifListToken extends CommonToken {

    private Type t;
    
    public SpecifierQualifListToken(int tNode, Type t){
        super(tNode, "SPEC_QUAL_LIST");
        this.t = t;
    }
    
    public Type get_type(){
        return this.t;
    }
}
