package symbolTable.namespace;

import errorHandling.AccessSpecViolation;
import errorHandling.AmbiguousReference;
import errorHandling.ChangingMeaningOf;
import errorHandling.ConflictingDeclaration;
import errorHandling.InvalidScopeResolution;
import errorHandling.Redefinition;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import symbolTable.types.Method;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class MethodDefinition implements DefinesNamespace{

    private class Block {

        private Map<String, MethodContentElement<? extends Type>> allSymbols = new HashMap<String, MethodContentElement<? extends Type>>();

        private Map<String, TypeDefinition> visibleTypeNames;

        /**
         * Null for the first compound statement.
         */
        private Block parentBlock;

        private Map<String, MethodContentElement<Type>> localDeclarations;
        
        private List<Block> childrenBlocks;
        
        private void insertInAllSymbols(String name, MethodContentElement<? extends Type> entry){
            this.allSymbols.put(name, entry);
        }
        
        private void checkForConflictsInDecl(String name, Type t, int line, int pos) throws ConflictingDeclaration{
            if(this.allSymbols.containsKey(name) == true){
                MethodContentElement<? extends Type> old_entry = this.allSymbols.get(name);
                throw new ConflictingDeclaration(name, t, old_entry.element, line, pos, fileName, old_entry.line, old_entry.pos);
            }
        }
        
        private void checkForChangingMeaningOfType(String name, Type new_entry, int line, int pos) throws ChangingMeaningOf {
            if(this.visibleTypeNames.containsKey(name) == true){
                TypeDefinition t = this.visibleTypeNames.get(name);
                throw new ChangingMeaningOf(name, name, new_entry, t, line, pos);
            }
        }
        
        public Block(Block parentBlock, Map<String, TypeDefinition> parentsVisibleTypeNames){
            this.parentBlock = parentBlock;
            if(parentsVisibleTypeNames != null){
                this.visibleTypeNames = new HashMap<String, TypeDefinition>(parentsVisibleTypeNames);
            }
            else{
                this.visibleTypeNames = new HashMap<String, TypeDefinition>(methSignature.getParent().getVisibleTypeNames());
            }
        }
        
        public void insertLocalDeclaration(String name, Type decl, int line, int pos) throws ConflictingDeclaration, ChangingMeaningOf{
            if(this.localDeclarations == null) this.localDeclarations = new HashMap<String, MethodContentElement<Type>>();
            this.checkForConflictsInDecl(name, decl, line, pos);
            this.checkForChangingMeaningOfType(name, decl, line, pos);

            MethodContentElement<Type> elem = new MethodContentElement<Type>(decl, line, pos);
            this.localDeclarations.put(name, elem);
            
            this.insertInAllSymbols(name, elem);
        }
        
        public void findAllCandidates(String name, List<MethodContentElement<? extends Type>> declarations, List<TypeDefinition> types){
            
            if(this.localDeclarations != null && this.localDeclarations.containsKey(name)){
                declarations.add(this.localDeclarations.get(name));
            }
            
            if(declarations.isEmpty() && types.isEmpty() && this.parentBlock != null) this.parentBlock.findAllCandidates(name, declarations, types);
        
        }

        /*public void insertLocalMethDeclaration(String name, Method methDecl, int line, int pos) throws ConflictingDeclaration, ChangingMeaningOf{
            if(this.localMethsDeclarations == null) this.localMethsDeclarations = new HashMap<String, Map<Method.Signature, MethodContentElement<Method>>>();
            
            MethodContentElement<Method> methElem = new MethodContentElement<Method>(methDecl, line, pos);
            
            if(!this.localMethsDeclarations.containsKey(name)){
                this.checkForConflictsInDecl(name, methDecl, line, pos);
                this.checkForChangingMeaningOfType(name, methDecl, line, pos);
                this.localMethsDeclarations.put(name, new HashMap<Method.Signature, MethodContentElement<Method>>());
            }
            
            Map<Method.Signature, MethodContentElement<Method>> meths = this.localMethsDeclarations.get(name);
            
            meths.put(methDecl.getSignature(), methElem);
        }*/
        
        public Block getParentBlock(){
            return this.parentBlock;
        }
        
        public void addChildBlock(Block newChild){
            if(this.childrenBlocks == null) this.childrenBlocks = new ArrayList<Block>();
            
            this.childrenBlocks.add(newChild);
        }

    }
    
    private class MethodContentElement<T> implements MemberElementInfo<T> {

        private T element;
        
        private int line, pos;
        
        public MethodContentElement(T element, int line, int pos){
            this.element = element;
            this.line = line;
            this.pos = pos;
        }
        
        @Override
        public boolean equals(Object o){
            if(o == null) return false;
            if(o == this) return true;
            
            if(!(o instanceof MethodContentElement)) return false;
            
            MethodContentElement<?> othElem = (MethodContentElement<?>)o;
            
            if(!this.element.equals(othElem)) return false;
            
            if(!fileName.equals(othElem.getFileName())) return false;
            
            if(this.line != othElem.line) return false;
            
            if(this.pos != othElem.pos) return false;
            
            return true;
        }

        @Override
        public int hashCode() {
            int hash = 5;
            hash = 37 * hash + this.element.hashCode();
            hash = 37 * hash + fileName.hashCode();
            hash = 37 * hash + this.line;
            hash = 37 * hash + this.pos;
            return hash;
        }
        
        @Override
        public String getFileName() {
            return fileName;
        }

        @Override
        public int getLine() {
            return this.line;
        }

        @Override
        public int getPos() {
            return this.pos;
        }

        @Override
        public T getElement() {
            return this.element;
        }

        @Override
        public boolean isStatic() {
            return false;
        }

        @Override
        public boolean isClassMember() {
            return false;
        }

        @Override
        public boolean isDefined() {
            return true;
        }

        @Override
        public void defineStatic(int defLine, int defPos, String defFilename) {
            throw new UnsupportedOperationException("Definition of a method element is the declaration point.");
        }

        @Override
        public int getStaticDefLine() {
            return this.getLine();
        }

        @Override
        public int getStaticDefPos() {
            return this.getPos();
        }

        @Override
        public String getStaticDefFile() {
            return this.getFileName();
        }
        
        
        
    }

    private String name;

    private Method methSignature;
    
    private DefinesNamespace definedIn;
    
    private DefinesNamespace belongsTo;

    private String fileName;
    
    private Block mainBlock;
    
    private Block currentBlock;
    
    private Map<String, MethodContentElement<Type>> parameters;
    
    public MethodDefinition(DefinesNamespace definedIn){
        this.definedIn = definedIn;
    }
    
    public void setName(String name){
        this.name = name;
    }
    
    public void setMethodSign(Method m){
        this.methSignature = m;
    }
    
    public void enterNewBlock(){
        if(this.mainBlock == null){
            this.mainBlock = this.currentBlock = new Block(null, null);
            if(this.parameters != null){
                for(String paramName : this.parameters.keySet()){
                    MethodContentElement<Type> elem = this.parameters.get(paramName);
                    try {
                        this.mainBlock.insertLocalDeclaration(paramName, elem.element, elem.line, elem.pos);
                    } 
                    /*
                     * These exceptions are handled by the insert parameter method.
                     */
                    catch (ConflictingDeclaration | ChangingMeaningOf ex) {

                    }
                }
            }
        }
        else{
            Block newBlock = new Block(currentBlock, currentBlock.visibleTypeNames);
            this.currentBlock.addChildBlock(newBlock);
            this.currentBlock = newBlock;
        }
    }

    public void exitBlock(){
        Block parentBlock = this.currentBlock.parentBlock;
        this.currentBlock = parentBlock == null ? this.currentBlock : parentBlock;
    }
    
    /*
     * DefinesNamespace methods.
     */
    @Override
    public StringBuilder getStringName(StringBuilder in) {
        StringBuilder parents = this.belongsTo.getStringName(in);
        return parents.append(parents.toString().equals("") ? "" : "::").append(name);
    }

    @Override
    public Map<String, TypeDefinition> getVisibleTypeNames() {
        return this.currentBlock != null ? this.currentBlock.visibleTypeNames : this.belongsTo.getVisibleTypeNames();
    }

    @Override
    public DefinesNamespace getParentNamespace() {
        return this.belongsTo;
    }

    @Override
    public String getFullName() {
        return this.getStringName(new StringBuilder()).toString();
    }

    @Override
    public String getName() {
        return this.name;
    }

    @Override
    public TypeDefinition isValidTypeDefinition(String name, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference {
        TypeDefinition rv;
        
        rv = this.findTypeDefinition(name, null, true);
        
        if(rv == null) rv = this.belongsTo.isValidTypeDefinition(name, ignore_access);
        
        return rv;
    }

    @Override
    public TypeDefinition findTypeDefinition(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference {
        
        LookupResult res = this.localLookup(name, null, false, true);
        
        return res.isResultType();
    }

    @Override
    public DefinesNamespace findNamespace(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference, InvalidScopeResolution {
        return this.belongsTo.findNamespace(name, from_scope, ignore_access);
    }

    @Override
    public DefinesNamespace findInnerNamespace(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference, InvalidScopeResolution {
        return this.belongsTo.findInnerNamespace(name, from_scope, ignore_access);
    }

    @Override
    public LookupResult localLookup(String name, DefinesNamespace _, boolean __, boolean ___) {
        List<MethodContentElement<? extends Type>> decls = new ArrayList<MethodContentElement<? extends Type>>();
        List<TypeDefinition> types = new ArrayList<TypeDefinition>();
        
        if(this.currentBlock != null){
            this.currentBlock.findAllCandidates(name, decls, types);
        }

        return new LookupResult(name, types, null, decls, null, null, null, true);
    }

    @Override
    public boolean isEnclosedInNamespace(DefinesNamespace namespace) {
        boolean rv = false;
        DefinesNamespace curr = this.definedIn;

        while(curr != null){
            if(curr == namespace){
                rv = true;
                break;
            }
            curr = curr.getParentNamespace();
        }
        return rv;
    }
    
    /*
     * End DefinesNamespace methods
     */
    
    public void insertLocalDeclaration(String name, Type decl, int line, int pos) throws ConflictingDeclaration, ChangingMeaningOf{
        this.currentBlock.insertLocalDeclaration(name, decl, line, pos);
    }

    public void insertParameter(String name, Type t, int line, int pos) throws Redefinition, ChangingMeaningOf{
        if(this.parameters == null) this.parameters = new HashMap<String, MethodContentElement<Type>>();
        
        Map<String, TypeDefinition> visibleTypeNames = this.belongsTo.getVisibleTypeNames();
        if(visibleTypeNames.containsKey(name)){
            TypeDefinition typedef = visibleTypeNames.get(name);
            throw new ChangingMeaningOf(name, name, t, typedef, line, pos);
        }
        
        if(!this.parameters.containsKey(name)){
            MethodContentElement<Type> elem = new MethodContentElement<Type>(t, line, pos);
            this.parameters.put(name, elem);
        }
        else{
            MethodContentElement<Type> old_entry = this.parameters.get(name);
            throw new Redefinition(name, t, line, pos, old_entry.element, fileName, old_entry.line, old_entry.pos);
        }
    }

    public DefinesNamespace getDefinedInNamespace(){
        return this.definedIn;
    }

    public void setBelongsTo(DefinesNamespace belonngsTo){
        this.belongsTo = belonngsTo;
    }
}
