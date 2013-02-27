package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.namespace.Namespace;

/**
 *
 * @author kostas
 */
public class NamespaceToken extends CommonToken {

    private Namespace namespace;
    
    public NamespaceToken(int tNode, Namespace nmspace){
        super(tNode, "NAMESPACE");
        this.namespace = nmspace;
    }

    public Namespace getNamespace(){
        return this.namespace;
    }
}
