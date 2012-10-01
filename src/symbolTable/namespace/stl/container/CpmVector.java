/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package symbolTable.namespace.stl.container;

import java.util.HashMap;
import symbolTable.namespace.CpmClass;
import symbolTable.namespace.DefinesNamespace;
import symbolTable.namespace.SynonymType;
import symbolTable.namespace.stl.iterator.CpmIterator;
import symbolTable.namespace.stl.iterator.IteratorType;
import symbolTable.types.UserDefinedType;

/**
 *
 * @author kostas
 */
public class CpmVector extends CpmClass{

    SynonymType parameter_type = new SynonymType("T", null, this);

    public CpmVector(DefinesNamespace belongsTo){
        /*
         * access is null because vector belongs to std namespace
         */
        super("class", "vector", belongsTo, null, true);
        
        this.innerSynonyms = new HashMap<String, ClassContentElement<SynonymType>>();
        this.innerTypes = new HashMap<String, ClassContentElement<CpmClass>>();
        
        CpmIterator iterator = new CpmIterator("iterator", this, AccessSpecifier.Public, null, IteratorType.RandomAccess, false);
        CpmIterator const_iterator = new CpmIterator("const_iterator", this, AccessSpecifier.Public, null, IteratorType.RandomAccess, true);
        CpmIterator reverse_iterator = new CpmIterator("reverse_iterator", this, AccessSpecifier.Public, null, IteratorType.RandomAccess, false);
        CpmIterator const_reverse_iterator = new CpmIterator("const_reverse_iterator", this, AccessSpecifier.Public, null, IteratorType.RandomAccess, true);
        
        this.innerTypes.put("iterator", new ClassContentElement<CpmClass>(iterator, AccessSpecifier.Public, false, "vector", -1, -1));
        this.innerTypes.put("const_iterator", new ClassContentElement<CpmClass>(const_iterator, AccessSpecifier.Public, false, "vector", -1, -1));
        this.innerTypes.put("reverse_iterator", new ClassContentElement<CpmClass>(reverse_iterator, AccessSpecifier.Public, false, "vector", -1, -1));
        this.innerTypes.put("const_reverse_iterator", new ClassContentElement<CpmClass>(const_reverse_iterator, 
                                                                                        AccessSpecifier.Public, 
                                                                                        false,
                                                                                        "vector", -1, -1));
        
        SynonymType inputIterator = new SynonymType("InputIterator", new UserDefinedType(const_iterator, false, false), this);
        this.innerSynonyms.put("T", new ClassContentElement<SynonymType>(parameter_type, AccessSpecifier.Private, false, null, -1, -1));
        this.innerSynonyms.put("InputIterator", new ClassContentElement<SynonymType>(inputIterator, AccessSpecifier.Private, false, null, -1, -1));
    }
}
