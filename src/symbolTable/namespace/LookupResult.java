package symbolTable.namespace;

import errorHandling.AccessSpecViolation;
import errorHandling.AmbiguousReference;
import errorHandling.InvalidScopeResolution;
import errorHandling.NotMatchingPrototype;
import java.util.List;
import java.util.Map;
import symbolTable.types.Method;
import symbolTable.types.Type;

/**
 * LookupResult represents the result of a name lookup. That is, when an identifier
 * has to be mapped to a certain symbol in the program (e.g., a use of a variable to its declaration)
 * a name lookup is being performed. This class besides aggregating all the results for the previous
 * identifier, also provides an interface in order to determine what element the result is (e.g., a type
 * definition, a method, a field, etc.). Last but not least, this class is also responsible for creating
 * error message that have to do with ambiguous references, access specifiers violations, etc.
 *
 * @author kostas
 */
public class LookupResult {

    /**
     * The identifier for the name lookup. 
     */
    String nameForLookup;
    
    /**
     * All the candidate types returned by the lookup.
     */
    List<TypeDefinition> candidateTypes;
    
    /**
     * All the candidate namespaces returned by the lookup.
     * Can be null, since for example classes do not contain
     * namespaces,
     */
    List<Namespace> candidateNamespaces;
    
    /**
     * All the candidate fields returned by the lookup.
     */
    List<? extends MemberElementInfo<? extends Type>> candidateFields;
    
    /**
     * All the candidate methods returned by the lookup.
     * This list can be merged with the above, but it is
     * more comfortable to have a separate list for the methods
     * in order to check for matching prototypes.
     */
    List<Map<Method.Signature, ? extends MemberElementInfo<Method>>> candidateMethods;
    
    /**
     * Access errors for types.
     */
    Map<TypeDefinition, String> accessErrForTypes;
    
    /**
     * Access errors for fields.
     */
    Map<? extends MemberElementInfo<? extends Type>, String> accessErrForFields;
    
    /**
     * AccessSpecViolation exceptions are being thrown only if this flag is false.
     * It is needed for cases that the access specifier for an element is not taken
     * under consideration (e.g., defining a private method outside a class).
     */
    boolean ignore_access;
    
    /**
     * Constructs an object with the specified name, candidate types, candidate namespaces,
     * candidate fields, candidate methods, access errors for types and fields.
     * 
     * @param nameForLookup the name for the lookup.
     * @param candidatesTypes all the candidate types returned by the lookup process.
     * @param candidateNamespaces all the candidate namespaces returned by the lookup process.
     * @param candidateFields all the candidate fields returned by the lookup process.
     * @param candidateMethods all the candidate methods returned by the lookup process.
     * @param accessErrForTypes  all the access errors for types.
     * @param accessErrForFields all the access errors for fields.
     * @param ignore_access flag for the access error messages,i.e., ignored if true.
     */
    public LookupResult(String nameForLookup,
                        List<TypeDefinition> candidatesTypes,
                        List<Namespace> candidateNamespaces,
                        List<? extends MemberElementInfo<? extends Type>> candidateFields,
                        List<Map<Method.Signature, ? extends MemberElementInfo<Method>>> candidateMethods,
                        Map<TypeDefinition, String> accessErrForTypes,
                        Map<? extends MemberElementInfo<? extends Type>, String> accessErrForFields,
                        boolean ignore_access){

        this.nameForLookup = nameForLookup;
        this.candidateTypes = candidatesTypes;
        this.candidateFields = candidateFields;
        this.candidateMethods = candidateMethods;
        this.candidateNamespaces = candidateNamespaces;
        this.accessErrForTypes = accessErrForTypes;
        this.accessErrForFields = accessErrForFields;
        this.ignore_access = ignore_access;
    }
    
    private int getResultsize(){
        return candidateTypes.size() + (candidateNamespaces == null ? 0 : candidateNamespaces.size())
                      + candidateFields.size() + (candidateMethods == null ? 0 : candidateMethods.size());
    }

    /**
     * Checks if the result is ambiguous. That is the requested name maps to more than one elements.
     * @throws AmbiguousReference If the lookup is ambiguous.
     */
    private void checkForAmbiguity() throws AmbiguousReference{
        int resSize = this.getResultsize();
        
        if(resSize > 1) throw new AmbiguousReference(candidateTypes, candidateNamespaces, candidateFields, candidateMethods, nameForLookup);
    }
    
    public boolean isResultEmpty() {
        return this.getResultsize() == 0;
    }
    
    /**
     * Checks if lookup's result is a type and returns the appropriate type information.
     * 
     * @return The TypeDefinition object for the result or null if the result is not a type.
     * @throws AccessSpecViolation If the type is not accessible and the ignore_access is set to false.
     * @throws AmbiguousReference  If the reference to the name is ambiguous.
     */
    public TypeDefinition isResultType() throws AccessSpecViolation, AmbiguousReference{
        this.checkForAmbiguity();
        TypeDefinition rv = null;
        if(this.candidateTypes.size() == 1){
            rv = this.candidateTypes.get(0);
            
            if(this.ignore_access == false && this.accessErrForTypes != null && this.accessErrForTypes.containsKey(rv) == true)
                throw new AccessSpecViolation(this.accessErrForTypes.get(rv));
        }
        return rv;
    }
    
    /**
     * Checks if the result defines a namespace (i.e., a class or an actual namespace).
     * 
     * @return The DefinesNamespace object for the result or null in case of an error.
     * @throws AccessSpecViolation If the type is not accessible and the ignore_access is set to false.
     * @throws AmbiguousReference  If the reference to the name is ambiguous.
     * @throws InvalidScopeResolution If there is a result, but it does not defines a namespace (e.g., a typedef).
     */
    public DefinesNamespace doesResultDefinesNamespace() throws AmbiguousReference, AccessSpecViolation, InvalidScopeResolution {
        this.checkForAmbiguity();
        DefinesNamespace rv = null;
        if(this.candidateTypes.size() == 1){
            TypeDefinition possibleNamespace = this.candidateTypes.get(0);
            
            if(possibleNamespace instanceof DefinesNamespace){
                rv = (DefinesNamespace) possibleNamespace;
                
                if(this.ignore_access == false && this.accessErrForTypes != null && this.accessErrForTypes.containsKey(possibleNamespace) == true)
                    throw new AccessSpecViolation(this.accessErrForTypes.get(possibleNamespace));
            }
            else{
                throw new InvalidScopeResolution();
            }
        }
        else if(this.candidateNamespaces != null && this.candidateNamespaces.size() == 1){
            rv = this.candidateNamespaces.get(0);
        }
        
        
        return rv;
    }
    
    public MemberElementInfo<Method> isResultMethod(Method m, DefinesNamespace namespace) throws AmbiguousReference, AccessSpecViolation, NotMatchingPrototype{
        this.checkForAmbiguity();
        MemberElementInfo<Method> rv = null;
        
        if(this.candidateMethods != null && this.candidateMethods.size() == 1){
            Map<Method.Signature, ? extends MemberElementInfo<Method>> meth = this.candidateMethods.get(0);
            
            if(meth.containsKey(m.getSignature()) == true){
                rv = meth.get(m.getSignature());
                Method method = rv.getElement();
                if(!m.identical(method)){
                    throw new NotMatchingPrototype(this.nameForLookup, m, meth, namespace);
                }
            }
            else{
                throw new NotMatchingPrototype(this.nameForLookup, m, meth, namespace);
            }
            
            if(this.ignore_access == false && this.accessErrForFields != null && this.accessErrForFields.containsKey(rv))
                throw new AccessSpecViolation(this.accessErrForFields.get(rv));
        }
        
        return rv;
    }
    
    public MemberElementInfo<? extends Type> isResultField() throws AmbiguousReference, AccessSpecViolation {
        this.checkForAmbiguity();
        MemberElementInfo<? extends Type> rv = null;
        
        if(this.candidateFields.size() == 1){
            rv = this.candidateFields.get(0);
            
            if(this.ignore_access == false && this.accessErrForFields  != null && this.accessErrForFields.containsKey(rv) == true)
                throw new AccessSpecViolation(this.accessErrForFields.get(rv));
        }
        
        return rv;
    }


}
