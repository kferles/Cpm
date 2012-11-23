package symbolTable.namespace.stl.container;

import errorHandling.InvalidStlArguments;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import symbolTable.namespace.CpmClass;
import symbolTable.namespace.DefinesNamespace;
import symbolTable.namespace.SynonymType;
import symbolTable.namespace.stl.iterator.CpmIterator;
import symbolTable.namespace.stl.iterator.IteratorType;
import symbolTable.types.Type;
import symbolTable.types.UserDefinedType;

/**
 *
 * @author kostas
 */
public class CpmVector extends StlContainer {

    SynonymType parameter_type = new SynonymType("T", null, this);

    public CpmVector(DefinesNamespace belongsTo){
        /*
         * access is null because vector belongs to std namespace
         */
        super("vector", belongsTo);
        
        this.innerSynonyms = new HashMap<String, ClassContentElement<SynonymType>>();
        this.innerTypes = new HashMap<String, ClassContentElement<CpmClass>>();
        this.unknownTypes = new HashSet<Type>();
        
        CpmIterator iterator = new CpmIterator("iterator", this, AccessSpecifier.Public, null, IteratorType.RandomAccess, false);
        CpmIterator const_iterator = new CpmIterator("const_iterator", this, AccessSpecifier.Public, null, IteratorType.RandomAccess, true);
        CpmIterator reverse_iterator = new CpmIterator("reverse_iterator", this, AccessSpecifier.Public, null, IteratorType.RandomAccess, false);
        CpmIterator const_reverse_iterator = new CpmIterator("const_reverse_iterator", this, AccessSpecifier.Public, null, IteratorType.RandomAccess, true);
        
        this.innerTypes.put("iterator", new ClassContentElement<CpmClass>(iterator, AccessSpecifier.Public, false, "vector", -1, -1));
        this.unknownTypes.add(new UserDefinedType(iterator, false, false));
        
        this.innerTypes.put("const_iterator", new ClassContentElement<CpmClass>(const_iterator, AccessSpecifier.Public, false, "vector", -1, -1));
        this.unknownTypes.add(new UserDefinedType(const_iterator, false, false));
        
        this.innerTypes.put("reverse_iterator", new ClassContentElement<CpmClass>(reverse_iterator, AccessSpecifier.Public, false, "vector", -1, -1));
        this.unknownTypes.add(new UserDefinedType(reverse_iterator, false, false));
        
        this.innerTypes.put("const_reverse_iterator", new ClassContentElement<CpmClass>(const_reverse_iterator, 
                                                                                        AccessSpecifier.Public, 
                                                                                        false,
                                                                                        "vector", -1, -1));
        this.unknownTypes.add(new UserDefinedType(const_reverse_iterator, false, false));
        
        this.innerSynonyms.put("T", new ClassContentElement<SynonymType>(parameter_type, AccessSpecifier.Private, false, null, -1, -1));
        this.unknownTypes.add(new UserDefinedType(parameter_type, false, false));
        
        SynonymType inputIterator = new SynonymType("InputIterator", new UserDefinedType(const_iterator, false, false), this);
        this.innerSynonyms.put("InputIterator", new ClassContentElement<SynonymType>(inputIterator, AccessSpecifier.Private, false, null, -1, -1));
        this.unknownTypes.add(new UserDefinedType(inputIterator, false, false));
    }
    
    public CpmVector(CpmVector vector, Type t){
        super(vector);

        super.templateArguments = new ArrayList<Type>();
        super.templateArguments.add(t);
        
        String[] templateArgs = new String[] {"T", "InputIterator"};
        String[] iteratorNames = new String [] {"iterator",
                                                "const_iterator", 
                                                "reverse_iterator", 
                                                "const_reverse_iterator"};

        Map<String, UserDefinedType> newTypes = new HashMap<String, UserDefinedType>();
        
        this.instatiateIterators(iteratorNames, t, newTypes);

        this.instatiateTemplateArguments(templateArgs, new SynonymType[] {new SynonymType("T", t, this),
                                                                          new SynonymType("InputIterator",
                                                                                           new UserDefinedType(this.innerTypes.get("const_iterator").getElement(),
                                                                                           false,
                                                                                           false), 
                                                                                           this)
                                                                          }, newTypes);
        
        this.replaceUknownTypes(vector, newTypes);

    }
    
    @Override
    public CpmVector instantiate(List<Type> arguments) throws InvalidStlArguments{

        if(arguments.size() != 1){
            throw new InvalidStlArguments("vector", "'vector' takes only one template argument T (Type of the elements)");
        }

        Type t = arguments.get(0);

        return new CpmVector(this, t);
    }

}
