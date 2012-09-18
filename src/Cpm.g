/** ANSI C ANTLR v3 grammar

Translated from Jutta Degener's 1995 ANSI C yacc grammar by Terence Parr
July 2006.  The lexical rules were taken from the Java grammar.

Jutta says: "In 1985, Jeff Lee published his Yacc grammar (which
is accompanied by a matching Lex specification) for the April 30, 1985 draft
version of the ANSI C standard.  Tom Stockfisch reposted it to net.sources in
1987; that original, as mentioned in the answer to question 17.25 of the
comp.lang.c FAQ, can be ftp'ed from ftp.uu.net,
   file usenet/net.sources/ansi.c.grammar.Z.
I intend to keep this version as cu discover discrepancies. Jutta Degener, 1995"

Generally speaking, you need symbol table info to parse C; typedefs
define types and then IDENTIFIERS are either types or plain IDs.  I'm doing
the min necessary here tracking only type names.  This is a good example
of the global scope (called Symbols).  Every rule that declares its usage
of Symbols pushes a new copy on the stack effectively creating a new
symbol scope.  Also note rule declaration declares a rule scope that
lets any invoked rule see isTypedef boolean.  It's much easier than
passing that info down as parameters.  Very lose to the current C Standard grammar as
possible; please let me know if yoclean.  Rule
direct_declarator can then easily determine whether the IDENTIFIER
should be declared as a type name.

I have only tested this on a single file, though it is 3500 lines.

This grammar requires ANTLR v3.0.1 or higher.

Terence Parr
July 2006
*/ 
grammar Cpm;
options {
    backtrack=true;
    memoize=true;
    k=2;
    output=AST;
}

scope Type_Spec{
	boolean error_for_signed, error_for_unsigned, error_for_short;
	boolean type[];
	//primitive types 
	PrimitiveTypeCheck counters;
	
	//user defined types
	NamedType named_t;
	int userDefinedCount;
	boolean error_inUserDefined;
	
	//forward declaration
	boolean isForwardDeclaration;
}

scope cv_qual{
	boolean error_for_const, error_for_volatile;
	int constCount;
	int volatileCount;
}

scope storage_class_spec{
	boolean error_found;
	int externCount;
	int staticCount;
	int autoCount;
	int registerCount;
}

scope function_spec{
	boolean error_for_explicit;
	boolean error_for_virtual;
	int explicitCount;
	int virtualCount;
}

scope declarator_strings{
	String dir_decl_identifier;
	String dir_decl_error;
}

scope decl_infered{
	DeclaratorInferedType declarator;
}

scope decl_id_info{
	int line;
	int pos;
}

scope collect_base_classes{
	ArrayList<CpmClass> superClasses;
}

@header {
import java.util.Set;
import java.util.HashSet;
import java.util.ArrayList;
import java.util.List;
import java.util.Stack;
import symbolTable.SymbolTable;
import symbolTable.types.*;
import symbolTable.namespace.*;
import errorHandling.*;
import preprocessor.*;
}

@parser::members {

	//Symbol Table
	private SymbolTable symbolTable = new SymbolTable();
	
	//Preprocessor Information
	PreprocessorInfo preproc = new PreprocessorInfo();

	//error messages
	
	private class DeclSpecifierError extends Exception{
	
		String error, init_delc_list_err;

		public DeclSpecifierError(String error, String init_decl_list_err){
			this.error = error;
			this.init_delc_list_err = init_decl_list_err;
		}

	}


	Stack paraphrases = new Stack();
	
	String pending_undeclared_err = null;
	
	AmbiguousReference pending_ambiguous = null;
	
	private void resetErrorMessageAuxVars(){
		pending_undeclared_err = null;
		pending_ambiguous = null;
		this.already_failed = false;
	}
	
	//to change the name of the file when i'll use the cpp utility
	//just override this on
	public String getSourceName(){
		return this.preproc.getCurrentFileName();
	}

	public void displayRecognitionError(String[] tokenNames, RecognitionException e) {
		//Change line number in error reporting HERE !!!!
		//System.out.println(e.input.getSourceName());
		System.err.print(this.preproc.getHeaderError());
		e.line = this.preproc.getOriginalFileLine(e.line);
		super.displayRecognitionError(tokenNames, e);
        }
	
	public String getErrorMessage(RecognitionException e, String[] tokenNames){
		//e.token.setLine(e.token.getLine()+1);
		if(paraphrases.size() > 0){
			String rv = "";
			for(Object o : paraphrases)
				rv += (String) o;
			paraphrases.clear();
			return rv;
		}
		if(pending_undeclared_err != null) {
			String rv = pending_undeclared_err;
			pending_undeclared_err = null;
			return rv;
		}
		if(pending_ambiguous != null){
			AmbiguousReference temp = pending_ambiguous;
			pending_ambiguous = null;
			yield_error(temp.getRefError());
		  	System.err.print(temp.getMessage(this.getSourceName()));
		  	return temp.getLastLine();
		}
		return super.getErrorMessage(e, tokenNames);
	}
	
	private Object error(String msg){
		paraphrases.push(msg);
		//throw new RecognitionException();
		return null;
	}
	
	private int fixLine(Token t){
		return this.preproc.getOriginalFileLine(t.getLine());
	}
	
	private void yield_error(String error){
		String fileName = this.getSourceName();
		error = fileName + " " + error;
		System.err.println(error);
	} 
	
	private void yield_error(String error, int line, int position){
		String fileName = this.getSourceName();
		error = fileName + " line " + line + ":" + position + " " + error;
		System.err.print(this.preproc.getHeaderError());
		System.err.println(error);
	}
	
	private void direct_declarator_error(String declarator, int line, int position, String error){
		if(error == null) return;
		String fileName = super.getSourceName();
		error = error + " '" + declarator + '\'';
		yield_error(error, line, position);
		//paraphrases.push(error);
	}
	
	private boolean const_count_error(){
		cv_qual_scope cv_quals = get_cv_qual_scope();
		if(cv_quals.error_for_const == true) return true;
		if(cv_quals.constCount > 1){
			cv_quals.error_for_const = true;
			paraphrases.push("error: duplicate 'const'");
			return false;
		}
		return true;
	}
	
	private boolean volatile_count_error(){
		cv_qual_scope cv_quals = get_cv_qual_scope();
		if(cv_quals.error_for_volatile == true) return true;
		if(cv_quals.volatileCount > 1){
			cv_quals.error_for_volatile = true;
			paraphrases.push("error: duplicate 'volatile'");
			return false;
		}
		return true;
	}
	
	private boolean virtual_count_error(){
		function_spec_scope fun_spec = get_function_spec_scope();
		if(fun_spec.error_for_virtual == true) return true;
		if(fun_spec.virtualCount > 1){
			fun_spec.error_for_virtual = true;
			paraphrases.push("error: duplicate 'virtual'");
			return false;
		}
		return true;
	}
	
	private boolean explicit_count_error(){
		function_spec_scope fun_spec = get_function_spec_scope();
		if(fun_spec.error_for_explicit == true) return true;
		if(fun_spec.explicitCount > 1){
			fun_spec.error_for_explicit = true;
			paraphrases.push("error: duplicate 'explicit'");
			return false;
		}
		return true;
	}
	
	private boolean storage_class_specs_error(){
		storage_class_spec_scope specs = get_storage_class_spec();
		if(specs.error_found == true) return true;
		if(specs.externCount
		   + specs.staticCount
		   + specs.autoCount
		   + specs.registerCount > 1){
		
			specs.error_found = true;
			paraphrases.push("error: conflicting or duplicated storage class specifiers");
		  	return false;
		}
		return true;
	}
	
	private boolean signed_count_error(){
		Type_Spec_scope specs = get_Type_Spec_scope();
		if(specs.error_for_signed == true) return true;
		if(specs.counters.signedCount > 1){
			specs.error_for_signed = true;
			paraphrases.push("error: duplicate 'signed'");
			return false;
		}
		return true;
	}
	
	private boolean unsigned_count_error(){
		Type_Spec_scope specs = get_Type_Spec_scope();
		if(specs.error_for_unsigned == true) return true;
		if(specs.counters.unsignedCount > 1){
			specs.error_for_unsigned = true;
			paraphrases.push("error: duplicate 'unsigned'");
			return false;
		}
		return true;
	}
	
	private boolean short_count_error(){
		Type_Spec_scope specs = get_Type_Spec_scope();
		if(specs.error_for_short == true) return true;
		if(specs.counters.shortCount > 1){
			specs.error_for_short = true;
			paraphrases.push("error: duplicate 'short'");
			return false;
		}
		return true;
	}

	private boolean check_tags(String requested, NamedType original, int line, int pos){
		String tag = original.getTag();
		boolean isUnion = requested.equals("union");
		if(tag.equals("struct") == true || tag.equals("class") == true){
			if(isUnion){
				this.yield_error("error: 'union' tag used in naming '" + original.toString() + "'", line, pos);
				return false;
			}
		}
		else if(tag.equals("union") == true){
			if(!isUnion){
				this.yield_error("error: '" + requested + "' tag used in nameing '" + original.toString() + "'", line, pos);
				return false;
			}
		}
		
		return true;
	}
	
	//end error messages
	
	//AST construction
	
	Tree getChildren(CommonTree t){
		List l = t.getChildren();
		CommonTree rv = new CommonTree();
		if(l != null)
			for(Object o : l) rv.addChild((CommonTree)o);
		return rv;
	}
	
	Tree createTreeFromList(List nodes){
		CommonTree rv = new CommonTree();
		if(nodes != null)
			for(Object o : nodes) rv.addChild((CommonTree)o);
		return rv;
	}
	
	//end AST construction
	
	//Scopes
	
	//Type_Spec scope
	private class PrimitiveTypeCheck{
		int voidCount = 0,
		    charCount = 0,
		    shortCount = 0,
		    intCount = 0,
		    longCount = 0,
		    floatCount = 0,
		    doubleCount = 0,
		    boolCount = 0,
		    signedCount = 0,
		    unsignedCount = 0;
		    
		public Type checkSpecForPrimitives(boolean isConst, boolean isVolatile) throws DeclSpecifierError{
			int countDataTypes = voidCount + charCount   + intCount    
						       + floatCount  + doubleCount
						       + boolCount;
			
			int signs = signedCount + unsignedCount;

			//if(countDataTypes == 0) return; //error //is that possible?
			if(countDataTypes > 1) {
				throw new DeclSpecifierError("error: two or more data types in declaration", " of");
			}
			
			if(signedCount > 1 && unsignedCount > 1) {
				throw new DeclSpecifierError("error: 'signed' and 'unsigned' specified together", " for");
			}
			
			String type_name = "";
			
			if(voidCount == 1){
				if(signs != 0) {
					throw new DeclSpecifierError("error: 'signed' or 'unsigned' invalid", " for");
				}
				if(longCount != 0 || shortCount != 0) {
					throw new DeclSpecifierError("error: 'long' or 'short' invalid", " for");
				}
				type_name += "void";
			}
			else if(charCount == 1){
				if(longCount != 0 || shortCount != 0) {
					throw new DeclSpecifierError("error: 'long' or 'short' invalid", " for");
				}
				type_name += unsignedCount == 1 ? "unsigned " : "" + "char";
			}
			else if(intCount == 1){
				if(longCount > 0 && shortCount > 0){
					throw new DeclSpecifierError("error: 'long' and 'short' specified together", " for");
				}
				type_name += unsignedCount == 1 ? "unsigned " : "";
				if(longCount != 0){
					if(longCount > 2) {
						throw new DeclSpecifierError("error: 'long long long' invalid", " for");
					}
					for(int i = 0 ; i < longCount ; ++i) type_name += "long ";
				}
				else if(shortCount != 0){
					type_name += "short";
				}
				else{
					type_name += "int";
				}
			}
			else if(floatCount == 1){
				if(signs != 0) {
					throw new DeclSpecifierError("error: 'signed' or 'unsigned' invalid", " for");
				}
				if(longCount != 0 || shortCount != 0) {
					throw new DeclSpecifierError("error: 'long' or 'short' invalid", " for");
				}
				type_name += "float";
			}
			else if(doubleCount == 1){
				if(signs != 0) {
					throw new DeclSpecifierError("error: 'signed' or 'unsigned' invalid", " for");
				}
				if(shortCount > 1){
					throw new DeclSpecifierError("error: 'short' invalid", " for");
				}
				if(longCount > 1) {
					throw new DeclSpecifierError("error: 'long long' invalid", " for");
				}
				type_name += longCount == 1 ? "long " : "" + "double";
			}
			else if(boolCount == 1){
				if(signs != 0) {
					throw new DeclSpecifierError("error: 'signed' or 'unsigned' invalid", " for");
				}
				if(longCount != 0 || shortCount != 0) {
					throw new DeclSpecifierError("error: 'long' or 'short' invalid", " for");
				}
				type_name += "bool";
			}
			else if(shortCount != 0 && longCount == 0){
				type_name += unsignedCount == 1 ? "unsigned " : "" + "short";
			}
			else if(longCount != 0 && shortCount == 0){
				if(longCount > 2) {
					throw new DeclSpecifierError("error: 'long long long' invalid", " for");
				}
				type_name += unsignedCount == 1 ? "unsigned " : "";
				if(longCount == 1) type_name += "long";
				if(longCount == 2) type_name += "long long";
			}
			else{
				throw new DeclSpecifierError("error: 'long' and 'short' specified together", " for");
			}
			
			return new PrimitiveType(type_name, isConst, isVolatile);
		}
	}
	
	private Type_Spec_scope get_Type_Spec_scope(){
		Stack type_specs = Type_Spec_stack;
		return (Type_Spec_scope)type_specs.get(type_specs.size() - 1);
	}
	
	private void Type_Spec_at_init(){
		Type_Spec_scope specs = get_Type_Spec_scope();
		specs.error_for_signed = false;
		specs.error_for_unsigned = false;
		specs.type = new boolean[]{false,		//indicades primitive
					   false};		//user defined type
		specs.counters = new PrimitiveTypeCheck();
		specs.named_t = null;
		specs.userDefinedCount = 0;
		
		specs.isForwardDeclaration = false;
	}
	
	//End Type_Spec scope
	
	//cv_qual scope
	
	private cv_qual_scope get_cv_qual_scope(){
		Stack cv_qual_st = cv_qual_stack;
		return (cv_qual_scope)cv_qual_st.get(cv_qual_st.size() - 1);
	}
	
	
	private void cv_qual_at_init(){
		cv_qual_scope cv_quals = get_cv_qual_scope();
		cv_quals.constCount = cv_quals.volatileCount = 0;
		cv_quals.error_for_const = false;
		cv_quals.error_for_volatile = false;
	}
	//end cv_qual scope
	
	//function_spec scope
	
	private function_spec_scope get_function_spec_scope(){
		Stack function_spec_st = function_spec_stack;
		return (function_spec_scope)function_spec_st.get(function_spec_st.size() - 1);
	}
	
	private void function_spec_at_init(){
		function_spec_scope fun_specs = get_function_spec_scope();
		fun_specs.error_for_explicit = false;
		fun_specs.error_for_virtual = false;
		fun_specs.explicitCount = 0;
		fun_specs.virtualCount = 0;
	}
	
	//end function_spec scope
	
	//storage_class_spec
	
	private storage_class_spec_scope get_storage_class_spec(){
		Stack storage_class_spec_st = storage_class_spec_stack;
		return (storage_class_spec_scope) storage_class_spec_st.get(storage_class_spec_st.size() - 1);
	}
	
	private void storage_class_spec_at_init(){
		storage_class_spec_scope specs = get_storage_class_spec();
		specs.error_found = false;
		specs.externCount = 0;
		specs.staticCount = 0;
		specs.autoCount = 0;
		specs.registerCount = 0;
	}
	
	//end storage_class_spec
	
	//nested name id as type specifier aux methods and fields
	
	private boolean already_failed = false;
	
	private NamedType cached_named_t = null;
	
	private boolean isValidNamedType(ArrayList<String> chain, boolean explicitGlobalScope, boolean need_result){
		NamedType t = null;
		try{
			t = symbolTable.getNamedTypeFromNestedNameId(chain, explicitGlobalScope, false, false);
			if(need_result == true){
				cached_named_t = t;
				return true;
			}
			else if(t == null) already_failed = true;
		}
		catch(AccessSpecViolation access_viol){
			//if chain size is 1 the error must be pending
	  		yield_error(access_viol.getMessage());
	  		yield_error(access_viol.getContextError());
	  		already_failed = true;
	  	}
	  	catch(AmbiguousReference ambiguous){
	  		if(ambiguous.isPending() == false){
		  		yield_error(ambiguous.getRefError());
		  		System.err.print(ambiguous.getMessage(this.getSourceName()));
		  		yield_error(ambiguous.getLastLine());
		  		already_failed = true;
	  		}
	  		else{
	  			pending_ambiguous = ambiguous;
	  		}
	  	}
	  	catch(NotDeclared nodeclared){
  			yield_error(nodeclared.getMessage());
  			already_failed = true;
	  	}
	  	catch(InvalidScopeResolution invalid){
	  		yield_error(invalid.getMessage());
	  		already_failed = true;
	  	}
	  	catch(DoesNotNameType nt){
	  		pending_undeclared_err = nt.getMessage();
	  	}
	  	
	  	return t == null ? false : true;
	}
	
	private CpmClass isValidBaseClass(ArrayList<String> chain, boolean explicitGlobalScope, char token) throws Exception, BaseClassCVQual{
		CpmClass rv = null;
		try{
			NamedType named_t = symbolTable.getNamedTypeFromNestedNameId(chain, explicitGlobalScope, false, false);
			rv = named_t.isClassName();
			if(rv == null){
				throw new Exception("error: expected class-name before '" + token + "'");
			}
		}
		catch(AccessSpecViolation access_viol){
	  		yield_error(access_viol.getMessage());
	  		yield_error(access_viol.getContextError());
	  	}
	  	catch(AmbiguousReference ambiguous){
	  		if(ambiguous.isPending() == false){
		  		yield_error(ambiguous.getRefError());
		  		System.err.print(ambiguous.getMessage(this.getSourceName()));
		  		yield_error(ambiguous.getLastLine());
	  		}
	  		else{
	  			throw new Exception("error: expected class-name before '" + token + "'");
	  		}
	  	}
	  	catch(NotDeclared nodeclared){
  			throw new Exception("error: expected class-name before '" + token + "'");
	  	}
	  	catch(InvalidScopeResolution invalid){
	  		throw new Exception("error: expected class-name before '" + token + "'");
	  	}
	  	catch(DoesNotNameType nt){
	  		throw new Exception("error: expected class-name before '" + token + "'");
	  	}
	  	
	  	return rv;
	}
	
	//end nested name id as type specifier aux methods
	
	//declarator aux class and methods (to infer the type)
	
	private class ptr_cv{
	
		boolean isConst;
		
		boolean isVolatile;
	
		public ptr_cv(boolean isConst, boolean isVolatile){
			this.isConst = isConst;
			this.isVolatile = isVolatile;
		}
	}
	
	private class DeclaratorInferedType{ 
	
		Pointer p_rv = null;
		
		Method m_rv = null;
		
		CpmArray ar_rv = null;
		
		
		/*
		 * Pending types only one of the follow not null
		 */
		
		Pointer p_pend = null;
		
		Method m_pend = null;
		
		CpmArray ar_pend = null;
		
		public DeclaratorInferedType(Pointer p_rv, Pointer pending){
			this.p_rv = p_rv;
			this.p_pend = pending;
		}
		
		public DeclaratorInferedType(Method m_rv){
			this.m_rv = m_rv;
			this.m_pend = m_rv;
		}
		
		public DeclaratorInferedType(CpmArray ar_rv){
			this.ar_rv = ar_rv;
			this.ar_pend = ar_rv;
		}
		
		public void setPending(Pointer ptr, Pointer new_pending){
			if(this.p_pend != null){
				this.p_pend.setPointsTo(ptr);
				
			}
			else if(this.m_pend != null){
				this.m_pend.getSignature().setReturnValue(ptr);
				this.m_pend = null;
			}
			else if(ar_pend != null){
				this.ar_pend.setType(ptr);
				this.m_pend = null;
			}
			else return;
			
			this.p_pend = new_pending;
		}
		
		public void setPending(CpmArray ar) throws Exception{
			if(p_pend != null){
				this.p_pend.setPointsTo(ar);
				this.p_pend = null;
				this.ar_pend = ar;
			}
			else if(m_pend != null){
				this.m_pend = null;
				throw new Exception("declared as a function returning an array");
			}
			else if(ar_pend != null){
				this.ar_pend.increaseDimensions();
			}
		}
		
		public void setPending(Method m) throws Exception{
			
			if(p_pend != null){
				this.p_pend.setPointsTo(m);
				this.p_pend = null;
				this.m_pend = m;
			}
			else if(m_pend != null){
				this.m_pend = null;
				throw new Exception("declared as function returning a fuction");
			}
			else if(ar_pend != null){
				this.ar_pend = null;
				throw new Exception("declared as as array of functions");
			}
			
		}
	
	}
	
	//end declarator aux class and methods (to infer the type)
	
	//class for in class declarations specifiers
	
	private class InClassDeclSpec{
	
		boolean isVirtual;
		
		boolean isExplicit;
		
		boolean isStatic;
		
		public InClassDeclSpec(boolean isVirtual, boolean isExplicit, boolean isStatic){
			this.isVirtual = isVirtual;
			this.isExplicit = isExplicit;
			this.isStatic = isStatic;
		}
	}
	
	//end class for in class declarations specifiers
	
	//classes to collect all parametrs
	
	private class Param{
		Type t;
		String id;
	}
	
	private class ParameterList{
	
		ArrayList<Type> params = null;
		
		ArrayList<String> ids = null; 
		
		boolean hasVarargs = false;
	
		void insertParam(Param p){
			if(this.params == null){
				this.params = new ArrayList<Type>();
				this.ids = new ArrayList<String>();
			}
			
			this.params.add(p.t);
			this.ids.add(p.id);
		}
	}
	
	//end classes to collect all parametrs
	
	//insert into current scope
	
	private void insertClass(String name, CpmClass cpm_class){
		try{
			//for now static will be false for all types
			//if there is an actuall diff for static specifier i'll change this one
			this.symbolTable.insertInnerType(name, cpm_class, false);
		}
		catch(SameNameAsParentClass same_name){
			this.yield_error(same_name.getMessage());
		}
		catch(ConflictingDeclaration conflict){
			this.yield_error(conflict.getMessage());
			this.yield_error(conflict.getFinalError());
		}
		catch(Redefinition redef){
			this.yield_error(redef.getMessage());
			this.yield_error(redef.getFinalError());
		}
		catch(DiffrentSymbol diff){
			this.yield_error(diff.getMessage());
			this.yield_error(diff.getFinalError());
		}
	}
	
	private void insertSynonym(String declarator_id, Type data_type, int id_line, int id_pos, InClassDeclSpec class_specs){

		try{
			SynonymType syn = new SynonymType(declarator_id, data_type, this.symbolTable.getCurrentNamespace());
			syn.setLineAndPos(id_line, id_pos);
	
	  		if(class_specs.isStatic == true){
				this.yield_error("error: conflicting specifiers in declaration of '" + declarator_id +"'", id_line, id_pos);
			}
			else if(class_specs.isVirtual == true){
				this.yield_error("error: '" + declarator_id + "' declared as virtual type", id_line, id_pos);	
			}
			else if(class_specs.isExplicit == true){
				this.yield_error("error: only declarations of constructors can be 'explicit'", id_line, id_pos);
			}
			else{
				this.symbolTable.insertInnerSyn(declarator_id, syn);
			}
		}
		catch(SameNameAsParentClass sameName){
			this.yield_error(sameName.getMessage());
		}
                catch(ConflictingDeclaration conflict){
                	this.yield_error(conflict.getMessage());
                	this.yield_error(conflict.getFinalError());
                }
                catch(Redefinition redef){
                	this.yield_error(redef.getMessage());
                	this.yield_error(redef.getFinalError());
                }
                catch(DiffrentSymbol diffSymbol){
                	this.yield_error(diffSymbol.getMessage());
                	this.yield_error(diffSymbol.getFinalError());
                }
	}
	
	private void insertField(String declarator_id, Type t, int id_line, int id_pos, InClassDeclSpec class_specs){
		
		try{
			if(class_specs.isVirtual == true){
				this.yield_error("error: '" + declarator_id + "' declared as virtual type", id_line, id_pos);
			}
			else if(class_specs.isExplicit == true){
				this.yield_error("error: only declarations of constructors can be 'explicit'", id_line, id_pos);
			}
			else{
				CpmClass currentClass = null;
				if(this.symbolTable.isCurrentNamespaceClass() == true){
					currentClass = (CpmClass) this.symbolTable.getCurrentNamespace();
				}
				
				if(t.isComplete(currentClass) == true){
					this.symbolTable.insertField(declarator_id, t, class_specs.isStatic, id_line, id_pos);
				}
				else{
					this.yield_error("error: field '" + declarator_id + "' has incomplete type", id_line, id_pos);
				}
			}
		}
		catch(ConflictingDeclaration conflict){
                	this.yield_error(conflict.getMessage());
                	this.yield_error(conflict.getFinalError());
                }
                catch(DiffrentSymbol diffSymbol){
                	this.yield_error(diffSymbol.getMessage());
                	this.yield_error(diffSymbol.getFinalError());
                }
                catch(ChangingMeaningOf changeMean){
                	this.yield_error(changeMean.getMessage());
                	this.yield_error(changeMean.getFinalError());
                }
                catch(VoidDeclaration v_decl){
                	this.yield_error(v_decl.getMessage(declarator_id), id_line, id_pos);
                }
	}
	
	private void insertMethod(String declarator_id, Method m, int id_line, int id_pos, InClassDeclSpec class_specs){
	
		try{
			if(class_specs.isExplicit == true){
				this.yield_error("error: only declarations of constructors can be 'explicit'", id_line, id_pos);
			}
			else{
				m.setVirtual(class_specs.isVirtual);
				this.symbolTable.insertMethod(declarator_id, m, class_specs.isStatic, id_line, id_pos);
			}
		}
		catch(ConflictingDeclaration conflict){
                	this.yield_error(conflict.getMessage());
                	this.yield_error(conflict.getFinalError());
                } 
                catch(ChangingMeaningOf changeMean){
                	this.yield_error(changeMean.getMessage());
                	this.yield_error(changeMean.getFinalError());
                }
                catch(CannotBeOverloaded cBeoverld){
                	this.yield_error(cBeoverld.getMessage());
                	this.yield_error(cBeoverld.getFinalError());
                }
                catch(DiffrentSymbol diffSymbol){
                	this.yield_error(diffSymbol.getMessage());
                	this.yield_error(diffSymbol.getFinalError());
                }
                catch(ConflictingRVforVirtual confRv){
                	this.yield_error(confRv.getMessage(id_line, id_pos));
                	this.yield_error(confRv.getFinalError());
                }
                catch(InvalidCovariantForVirtual invalidCovariant){
                	this.yield_error(invalidCovariant.getMessage(id_line, id_pos));
                	this.yield_error(invalidCovariant.getFinalError());
                }
	
	}
	
	//end insert into current scope

	boolean normal_mode = true;

}

@lexer::members{

	boolean ignore_ws = true;

}

@synpredgate{ this.state.backtracking == 0 && this.normal_mode == true }


translation_unit
	: external_declaration+
	;
	
/** Either a function definition or any other kind of C decl/def.
 *  The LL(*) analysis algorithm fails to deal with this due to
 *  recursion in the declarator rules.  I'm putting in a
 *  manual predicate here so that we don't backtrack over
 *  the entire function.  Further, you get a better error
 *  as errors within the function itself don't make it fail
 *  to predict that it's a function.  Weird errors previously.
 *  Remember: the goal is to avoid backtrack like the plague
 *  because it makes debugging, actions, and errors harder.
 *
 *  Note that k=1 results in a much smaller predictor for the 
 *  fixed lookahead; k=2 made a few extra thousand lines. ;)
 *  I'll have to optimize that in the future.
 */
external_declaration
options {k=1;}
	: namespace_definition
	//| (/*!!!*/nested_name_id '::' declarator[null] '{') => extern_method_definition
	| (declaration_specifiers? declarator '{' )=> function_definition
	| declaration
	;
	
namespace_definition
	: 'namespace' IDENTIFIER '{' external_declaration*  '}'
	;
	
extern_method_definition
	: type_specifier nested_name_id '::' declarator compound_statement
	;
	
function_definition
scope{

	ArrayList<String> parameters_ids;

}
scope declarator_strings;
scope decl_infered;
@init{
	$declarator_strings::dir_decl_identifier = null;
	$decl_infered::declarator = null;
	$function_definition::parameters_ids = null;
	this.pending_undeclared_err = null;
	this.pending_ambiguous = null;
}
	: declaration_specifiers? /*set declarator error */ declarator compound_statement		// ANSI style only
	;
	
declaration
scope{
  boolean isTypedef;
}
@init{
  $declaration::isTypedef = false;
}
@after {
  this.resetErrorMessageAuxVars();
}
	: (struct_union_or_class IDENTIFIER ':' 'public') => struct_union_or_class_definition ';'
	| (struct_union_or_class IDENTIFIER '{') => struct_union_or_class_definition ';'
	| (struct_union_or_class nested_name_id ':' 'public') => extern_class_definition ';'
	| (struct_union_or_class nested_name_id '{') => extern_class_definition ';'
	|'typedef' { $declaration::isTypedef = true; } simple_declaration ';' // special case, looking for typedef	
	| simple_declaration ';'
	| line_marker
	;
 
simple_declaration
scope{
	boolean possible_fwd_decl;
	String[] inf;
	String tag;
}
@init{
	$simple_declaration::possible_fwd_decl = false;
	$simple_declaration::inf = null;
	$simple_declaration::tag = null;
}
 	:
	  declaration_specifiers 
	  decl_list = init_declarator_list[$declaration_specifiers.error != null ? $declaration_specifiers.error + $declaration_specifiers.init_decl_err : null,
	  				   $declaration_specifiers.t,
	  				   $declaration_specifiers.class_specs]?
	  {
	      if($decl_list.tree == null){
	      	  if($declaration_specifiers.isFwdDecl == false){
	      	  	if($simple_declaration::possible_fwd_decl == true && $declaration_specifiers.t != null){
	      	  		String name = $simple_declaration::inf[0];
	      	  		CpmClass _class = new CpmClass($simple_declaration::tag, 
	  					      name, 
	  					      symbolTable.getCurrentNamespace(),
	  					      symbolTable.getCurrentAccess(),
	  					      false);
	  			_class.setLineAndPos(Integer.parseInt($simple_declaration::inf[1]),
	  					     Integer.parseInt($simple_declaration::inf[2]));
	  			this.insertClass(name, _class);
	      	  	}
	      	  	else{
		      	  	if($declaration_specifiers.error != null){
		      	  		yield_error($declaration_specifiers.error, 
			      	  		    fixLine($declaration_specifiers.start),
			      	  		    $declaration_specifiers.start.getCharPositionInLine());
		      	  	}
		      	  	yield_error("error: declaration does not declare anything", 
		      	  		    fixLine($declaration_specifiers.start),
		      	  		    $declaration_specifiers.start.getCharPositionInLine());
	      	  	}
	      	  }
	      	  else if($declaration_specifiers.hasQuals){
	      	  	yield_error("error: qualifiers can only be specified for objects and functions",
	      	  		    fixLine($declaration_specifiers.start),
	      	  		    $declaration_specifiers.start.getCharPositionInLine());
	      	  }
	      }
	  }
	  ;
	  
	
template_declaration
	:  template_specifier declarator
	;
	
template_specifier 
	: nested_template_id '<' template_parameter_list '>'
	;
	
nested_template_id
	: nested_name_id '::' template_type_id
	| template_type_id
	;
	
template_parameter_list
options{k = 2;}
	: template_specifier
	| type_specifier ','? template_parameter_list
	| type_specifier
	;
	
template_type_id
	: IDENTIFIER
	;
	
declaration_specifiers returns [Type t, boolean isFwdDecl, boolean hasQuals, String error, String init_decl_err, InClassDeclSpec class_specs]
scope Type_Spec;
scope cv_qual;
scope storage_class_spec;
scope function_spec;
@init{
	Type_Spec_at_init();
	cv_qual_at_init();
	storage_class_spec_at_init();
	function_spec_at_init();
	$t = null;
        $error = null;
        $isFwdDecl = false;
	$hasQuals = false;
	$class_specs = null;
}
	:   (    storage_class_specifier {$hasQuals = true;}
        	|   type_qualifier {$hasQuals = true;}
        	|   type_specifier
        	|   function_specifier
            )+
             {
             	Type_Spec_scope type_specs = get_Type_Spec_scope();
             	cv_qual_scope cv_quals = get_cv_qual_scope();
             	function_spec_scope fun_specs = get_function_spec_scope();
             	storage_class_spec_scope storage_specs = get_storage_class_spec();
             	boolean isConst = cv_quals.constCount != 0 ? true : false,
             		isVolatile = cv_quals.volatileCount != 0 ? true : false;
             	
             	$class_specs = new InClassDeclSpec(fun_specs.virtualCount != 0 ? true : false,
             					   fun_specs.explicitCount != 0 ? true : false,
             					   storage_specs.staticCount != 0 ? true : false );
                             	
             	//count for data types in declarations specifiers
             	int countTypes = 0;
             	for(boolean t : type_specs.type) if(t == true) ++countTypes;
             	if(countTypes > 1){	//multiple data types
             		$error = "error: two or more data types in declaration";
             		$init_decl_err = " of";
             	}
             	else{
             		//declaration secifiers is for primitive type
             		if(type_specs.type[0] == true){
             			try{
             				$t = type_specs.counters.checkSpecForPrimitives(isConst, isVolatile);
             			}
             			catch(DeclSpecifierError ex){	
             				//erro in declaration specs for a primitive type
             				$error = ex.error;
             				$init_decl_err = ex.init_delc_list_err;
             			}
             		}
             		//declaration specifiers for user defined type
             		else if(type_specs.type[1] == true){
             			if(type_specs.userDefinedCount > 1){
             				$error = "error: two or more data types in declaration";
             				$init_decl_err = " of";
             			}
             			else{
             				if(type_specs.error_inUserDefined == false && type_specs.named_t != null){
             					$t = new UserDefinedType(type_specs.named_t, isConst, isVolatile);
             					$isFwdDecl = type_specs.isForwardDeclaration;
             				}
             			}
             		}
             		//other cases
             	}
             }
	;
	catch [EarlyExitException _]{
	
	}

	
	
function_specifier
	: virt = 'virtual'
	  {
	  	$function_spec::virtualCount++;
	  	if(this.symbolTable.isCurrentNamespaceClass() == false){
	  		this.yield_error("error: 'virtual' outside class declaration", this.fixLine($virt), $virt.getCharPositionInLine());
	  	}
	  }
	  { virtual_count_error() == true }?
	| 'explicit'
	  {
	  	$function_spec::explicitCount++;
	  }
	  { explicit_count_error() == true }?
	;
	
class_init_declarator_list[String error, Type data_type, InClassDeclSpec class_specs]
@init{
	this.normal_mode = true;
}
	: init_declarator_list[$error, $data_type, $class_specs]?
	;

init_declarator_list [String error, Type data_type, InClassDeclSpec class_specs]
	: init_declarator [$error, $data_type, $class_specs] (',' init_declarator[$error, $data_type, $class_specs])*
	;

init_declarator [String error, Type data_type, InClassDeclSpec class_specs]
scope declarator_strings;
scope decl_infered;
scope decl_id_info;
@init{
	$declarator_strings::dir_decl_identifier = null;
	$declarator_strings::dir_decl_error = $error;
	$decl_infered::declarator = null;
}
	: declarator ('=' initializer)?
	  {	//todo: error for typedef with initializer
	  	if($data_type != null){
		  	DeclaratorInferedType decl_inf_t = $decl_infered::declarator;
		  	String declarator_id = $declarator_strings::dir_decl_identifier;
		  	int id_line = $decl_id_info::line;
		  	int id_pos = $decl_id_info::pos;
		  	if(decl_inf_t == null) {
		  		System.out.println($data_type.toString(declarator_id));
		  		if($declaration.size() > 0 && $declaration::isTypedef == true){
		  			this.insertSynonym(declarator_id, $data_type, id_line, id_pos, $class_specs);
		  		}
		  		else{
	  				if(this.symbolTable.isCurrentNamespaceClass() == true){
	  					this.insertField(declarator_id, $data_type, id_line, id_pos, $class_specs);
	  				}
		  		}
		  	}
		  	else{
		  		boolean err_inDeclarator = false;
		  		if(decl_inf_t.p_pend != null){
		  			decl_inf_t.p_pend.setPointsTo($data_type);
		  		}
		  		else if(decl_inf_t.m_pend != null){
		  			decl_inf_t.m_pend.getSignature().setReturnValue($data_type);
		  		}
		  		else if(decl_inf_t.ar_pend != null){
		  			decl_inf_t.ar_pend.setType($data_type);
		  		}
		  		else err_inDeclarator = true;
		  		
		  		if(err_inDeclarator == false){
			  		if(decl_inf_t.p_rv != null){
			  			//System.out.println(declarator_id);
			  			System.out.println(decl_inf_t.p_rv.toString(declarator_id));
			  			if($declaration.size() > 0 && $declaration::isTypedef == true){
				  			this.insertSynonym(declarator_id, decl_inf_t.p_rv, id_line, id_pos, $class_specs);
				  		}
				  		else{
			  				if(this.symbolTable.isCurrentNamespaceClass() == true){
			  					this.insertField(declarator_id, decl_inf_t.p_rv, id_line, id_pos, $class_specs);
			  				}
				  		}
			  		}
			  		else if(decl_inf_t.m_rv != null){
			  			System.out.println(decl_inf_t.m_rv.toString(declarator_id));
			  			if($declaration.size() > 0 && $declaration::isTypedef == true){
				  			this.insertSynonym(declarator_id, decl_inf_t.m_rv, id_line, id_pos, $class_specs);
				  		}
				  		else{
			  				if(this.symbolTable.isCurrentNamespaceClass() == true){
			  					this.insertMethod(declarator_id, decl_inf_t.m_rv, id_line, id_pos, $class_specs);
			  				}
				  		}
			  			
			  		}
			  		else if(decl_inf_t.ar_rv != null){
			  			CpmArray ar = decl_inf_t.ar_rv;
			  			System.out.println(ar.toString(declarator_id));
			  			if($declaration.size() > 0 && $declaration::isTypedef == true){
				  			this.insertSynonym(declarator_id, ar, id_line, id_pos, $class_specs);
				  		}
				  		else{
			  				if(this.symbolTable.isCurrentNamespaceClass() == true){
			  					this.insertField(declarator_id, ar, id_line, id_pos, $class_specs);
			  				}
				  		}
			  		}
		  		}
		  	}
	  	}
	  }
	;
	
storage_class_specifier
	: 'extern'
	  {
	  	$storage_class_spec::externCount++;
	  }
	  {storage_class_specs_error() == true}?
	| 'static'
	  {
	  	$storage_class_spec::staticCount++;
	  }
	  {storage_class_specs_error() == true}?
	| 'auto'
	  {
	  	$storage_class_spec::autoCount++;
	  }
	  {storage_class_specs_error() == true}?
	| 'register'
	  {
	  	$storage_class_spec::registerCount++;
	  }
	  {storage_class_specs_error() == true}?
	;
	
type_specifier
	: 'void'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.voidCount++;
	  }
	| 'char'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.charCount++;
	  }
	| 'short'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.shortCount++;
	  }
	  {short_count_error() == true}?
	| 'int'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.intCount++;
	  }
	| 'long'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.longCount++;
	  }
	| 'float'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.floatCount++;
	  }
	| 'double'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.doubleCount++;
	  }
	| 'bool'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.boolCount++;
	  }
	| 'signed'		//this is the deafault, isn't it ?
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.signedCount++;
	  }
	  {signed_count_error() == true}?
	| 'unsigned'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.unsignedCount++;
	  }
	  {unsigned_count_error() == true}?
	| struct_union_or_class_specifier
	| nested_name_id  
	  { $Type_Spec::type[1] = true;
	    $Type_Spec::userDefinedCount++;
	    /*
	     * IMPROVE this so this method will not be called again (needs a more complex cache)
	     */
	    isValidNamedType($nested_name_id.names_chain, $nested_name_id.explicitGlobalScope, true);
	    $Type_Spec::named_t = cached_named_t;
	  }
	  /*
	   * Here also check if the nested_name_id is any other kind of symbol ...
	   */
	  { this.normal_mode == false ||
	    ((already_failed == false) 
	     && (cached_named_t != null || isValidNamedType($nested_name_id.names_chain, $nested_name_id.explicitGlobalScope, false) == true))}?
	  { cached_named_t = null; }
	/*| enum_specifier
	| nested_template_id*/
	;
	catch[FailedPredicateException ex]{
	
	}

	
nested_name_id returns [ArrayList<String> names_chain, boolean explicitGlobalScope]
scope{
  ArrayList<String> names;
}
@init{
  $nested_name_id::names = new ArrayList<String>();
  $explicitGlobalScope = input.LT(1).getText().equals("::") ? true : false;
  $names_chain = $nested_name_id::names;
}
	: '::'? name_id scope_resolution*
	;
	
scope_resolution
	: '::' name_id
	;

name_id
@init{
  Token id = input.LT(1);
  $nested_name_id::names.add(id.getText() + ";" + this.fixLine(id) + ";" + id.getCharPositionInLine());
}
    : IDENTIFIER 
    ;

struct_union_or_class_specifier
	: struct_union_or_class nested_name_id
	  {
	  	NamedType named_t = null;
	  	try{
	  		$Type_Spec::type[1] = true;
	  		$Type_Spec::userDefinedCount++;
	  		named_t = symbolTable.getNamedTypeFromNestedNameId($nested_name_id.names_chain, $nested_name_id.explicitGlobalScope, true, false);
	  		if(named_t == null){
	  			String info[] = $nested_name_id.names_chain.get(0).split(";");
	  			String name = info[0];
	  			int line = Integer.parseInt(info[1]);
	  			int pos = Integer.parseInt(info[2]);
	  			$Type_Spec::isForwardDeclaration = true; 
	  			CpmClass _class = new CpmClass($struct_union_or_class.start.getText(), 
	  					      name, 
	  					      symbolTable.getCurrentNamespace(),
	  					      symbolTable.getCurrentAccess(),
	  					      false);
	  			_class.setLineAndPos(line, pos);
	  			$Type_Spec::named_t = _class;
	  			this.insertClass(name, _class);
	  		}
	  		else if(named_t instanceof SynonymType){
	  			Token tag = $struct_union_or_class.start;
	  			this.yield_error("error: using typedef or enum name '" + named_t.getName() + "' after '" + tag.getText() + "'",
	  					  this.fixLine(tag),
	  					  tag.getCharPositionInLine());
	  			$Type_Spec::named_t = null;
	  		}
	  		else{
	  			$Type_Spec::named_t = named_t;
	  		}
	  		
	  	}
	  	catch(AccessSpecViolation access_viol){
	  		yield_error(access_viol.getMessage());
	  		yield_error(access_viol.getContextError());
	  	}
	  	catch(AmbiguousReference ambiguous){
	  		if($nested_name_id.names_chain.size() == 1){
	  			String info[] = $nested_name_id.names_chain.get(0).split(";");
	  			String name = info[0];
	  			int line = Integer.parseInt(info[1]);
	  			int pos = Integer.parseInt(info[2]);
	  			$Type_Spec::isForwardDeclaration = true;
	  			CpmClass _class = new CpmClass($struct_union_or_class.start.getText(), 
	  							   name, 
	  					      		   symbolTable.getCurrentNamespace(),
	  					      		   symbolTable.getCurrentAccess(),
	  					      		   false);
	  			_class.setLineAndPos(line, pos);
	  			$Type_Spec::named_t = _class;
	  			this.insertClass(name, _class);
	  		}
	  		else{
		  		yield_error(ambiguous.getRefError());
		  		System.err.print(ambiguous.getMessage(this.getSourceName()));
		  		yield_error(ambiguous.getLastLine());
	  		}
	  	}
	  	catch(NotDeclared nodeclared){
  			yield_error(nodeclared.getMessage());
	  	}
	  	catch(InvalidScopeResolution invalid){
	  		yield_error(invalid.getMessage());
	  	}
	  	catch(DoesNotNameType _){
	  		//not possible
	  	}
	  	
	  	if($Type_Spec::named_t == null){
	  		$Type_Spec::error_inUserDefined = true;
	  	}
	  	else{
	  		if($simple_declaration.size() > 0){
		  		if($nested_name_id.names_chain.size() == 1 && $Type_Spec::named_t.getParentNamespace() != this.symbolTable.getCurrentNamespace()) {
		  			$simple_declaration::possible_fwd_decl = true;
		  			$simple_declaration::inf = $nested_name_id.names_chain.get(0).split(";");
		  			$simple_declaration::tag = $struct_union_or_class.start.getText();
		  		}
		  		else{
		  			check_tags($struct_union_or_class.start.getText(), 
		  				   $Type_Spec::named_t,
		  				   this.fixLine($struct_union_or_class.start),
		  				   $struct_union_or_class.start.getCharPositionInLine());
		  		}
		  	}
	  	}
	  }
	;

struct_union_or_class_definition
scope{
	UserDefinedType t;
}
scope collect_base_classes;
@init{
	$struct_union_or_class_definition::t = null;
}
	: struct_union_or_class IDENTIFIER (':' { $collect_base_classes::superClasses = new ArrayList<CpmClass>(); } base_classes = base_class_list)?
	  {
	  	CpmClass _class = null;
	  	String name = $IDENTIFIER.text;
	  	String tag = $struct_union_or_class.start.getText();
	  	if($base_classes.tree == null){
	  		_class = new CpmClass(tag, name, symbolTable.getCurrentNamespace(), symbolTable.getCurrentAccess(), true);
	  	}
	  	else{
	  		_class = new CpmClass(tag, name, symbolTable.getCurrentNamespace(), $collect_base_classes::superClasses, symbolTable.getCurrentAccess());
	  	}
	  	$struct_union_or_class_definition::t = new UserDefinedType(_class, false, false);
	  	_class.setLineAndPos(this.fixLine($IDENTIFIER), $IDENTIFIER.pos);
	  	this.insertClass(name, _class);
	  	this.symbolTable.setCurrentScope(_class);
	  	if(tag.equals("struct") == true || tag.equals("union") == true){
	  		this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Public);
	  	}
	  	else {
	  		this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Private);
	  	}
	  }
	   // todo : init_declarator_list parameters
  	   '{' class_declaration_list '}' 
  	  {
  	  	this.symbolTable.endScope();
  	  }
  	  init_declarator_list[null, $struct_union_or_class_definition::t, new InClassDeclSpec(false, false, false)]?
	;
	
extern_class_definition
scope{
	UserDefinedType t;
}
scope collect_base_classes;
@init{
	$extern_class_definition::t = null;
}
	: struct_union_or_class nested_name_id (':' { $collect_base_classes::superClasses = new ArrayList<CpmClass>(); } base_classes = base_class_list)?
	  {
	  	NamedType t = null;
	  	ArrayList<String> chain = $nested_name_id.names_chain;
	  	boolean explicitGlobalScope = $nested_name_id.explicitGlobalScope;
	  	int line = this.fixLine($nested_name_id.start);
	  	int pos = $nested_name_id.start.getCharPositionInLine();
	  	if(explicitGlobalScope == true){
	  		this.yield_error("error: global qualification of class name is invalid in external class definition", line, pos);
	  	}
	  	else{
			try{
				t = symbolTable.getNamedTypeFromNestedNameId(chain, false, false, true);
			}
			catch(Exception _){
				this.yield_error("error: qualified name does not name a class", line, pos);
			}
		}
		CpmClass _class = null;
		if(t != null){
			if(t instanceof CpmClass){
				_class = (CpmClass) t;
				DefinesNamespace current = this.symbolTable.getCurrentNamespace();
				if(_class.isEnclosedInNamespace(current) == true){
					if(_class.isComplete() == true){
						this.yield_error("error: redefinition of '" + _class + "'", line, pos);
						this.yield_error("error: previous definition of '" + _class + "'", _class.getLine(), _class.getPosition());
					}
					else{
						String tag = $struct_union_or_class.start.getText();
						if(this.check_tags(tag, _class, 
								   this.fixLine($struct_union_or_class.start),
								   $struct_union_or_class.start.getCharPositionInLine()) == true){

							_class.setIsComplete(true);
							_class.setLineAndPos(line, pos);
							_class.setTag(tag);
							this.symbolTable.setCurrentScope(_class);
							CpmClass.AccessSpecifier acc = null;
							if((acc = this.symbolTable.getCurrentAccess()) != null
							    && acc != _class.getAccess()){
							    
							    this.yield_error("error: '" + _class + "' redeclared with different access", line, pos);
							}
							if($base_classes.tree != null){
								_class.visibleTypesThroughSuperClasses($collect_base_classes::superClasses);
							}
							$extern_class_definition::t = new UserDefinedType(_class, false, false);
							if(tag.equals("struct") == true || tag.equals("union") == true){
						  		this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Public);
						  	}
						  	else {
						  		this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Private);
						  	}
					  	}
					  	else{
					  		_class = null;
					  	}
					}
				}
				else{
					this.yield_error("error: declaration of '" + _class + "' in '" + current + "' which does not enclose '" 
							 + _class.getParentNamespace() + "'",
							 line, pos);
					_class = null;
				}
			}
			else{
				_class = null;
				this.yield_error("error: qualified name does not name a class", line, pos);
			}
		}
		
		if(_class == null){
			this.normal_mode = false;
		}
	  }
	 '{' class_declaration_list '}' 
	  {
  	  	this.symbolTable.endScope();
  	  }
  	  class_init_declarator_list[null, $extern_class_definition::t, new InClassDeclSpec(false, false, false)]
	;

base_class_list
options{ k=3; }
	: 'public' nested_name_id
	 {
	 	int line = this.fixLine($nested_name_id.stop);
	 	int pos = $nested_name_id.stop.getCharPositionInLine() + $nested_name_id.text.length();
	 	try{
	 		CpmClass base = isValidBaseClass($nested_name_id.names_chain, 
	 						 $nested_name_id.explicitGlobalScope,
	 						 ',');
	 		if(base != null){
		 		if(base.isComplete() == false){
		 			this.yield_error("error: invalid use of incomplete type '" + base + "'", line, pos);
		 			this.yield_error("error: forward declaration of '" + base + "'", base.getLine(), base.getPosition());
		 		}
		 		else if(((DefinesNamespace) base) == this.symbolTable.getCurrentNamespace()){
		 			this.yield_error("error: invalid use of incomplete type '" + base + "'", line, pos);
		 			this.yield_error("error: forward declaration of '" + base + "'", base.getLine(), base.getPosition());
		 		}
		 		else if($collect_base_classes::superClasses.contains(base) == true){
		 			this.yield_error("error: duplicate base type '" + base + "' invalid", line, pos);
		 		}
		 		else{
		 			$collect_base_classes::superClasses.add(base);
		 		}
	 		}
	 	}
	 	catch(BaseClassCVQual quals){
	 		this.yield_error(quals.getMessage(), line, pos);
	 	}
	 	catch(Exception ex){
	 		this.yield_error(ex.getMessage(), line, pos);
	 	}
	 
	 }
	 ',' base_class_list
	| 'public' nested_name_id
	  {
	 	int line = this.fixLine($nested_name_id.stop);
	 	int pos = $nested_name_id.stop.getCharPositionInLine()  + $nested_name_id.text.length();
	 	try{
	 		CpmClass base = isValidBaseClass($nested_name_id.names_chain, 
	 						 $nested_name_id.explicitGlobalScope, 
	 						 '{');
	 		if(base != null){
		 		if(base.isComplete() == false){
		 			this.yield_error("error: invalid use of incomplete type '" + base + "'", line, pos);
		 			this.yield_error("error: forward declaration of '" + base + "'", base.getLine(), base.getPosition());
		 		}
		 		else if(((DefinesNamespace) base) == this.symbolTable.getCurrentNamespace()){
		 			this.yield_error("error: invalid use of incomplete type '" + base + "'", line, pos);
		 			this.yield_error("error: forward declaration of '" + base + "'", base.getLine(), base.getPosition());
		 		}
		 		else if($collect_base_classes::superClasses.contains(base) == true){
		 			this.yield_error("duplicate base type '" + base + "' invalid", line, pos);
		 		}
		 		else{
		 			$collect_base_classes::superClasses.add(base);
		 		}
	 		}
	 	}
	 	catch(BaseClassCVQual quals){
	 		this.yield_error(quals.getMessage(), line, pos);
	 	}
	 	catch(Exception ex){
	 		this.yield_error(ex.getMessage(), line, pos);
	 	}
	 
	 }
	;	
    
struct_union_or_class
	: 'struct'
	| 'union'
	| 'class'
	;
	
access_specifier
	: 'private'   { this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Private); }
	| 'protected' { this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Protected); }
	| 'public'    { this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Public); }
	;

class_declaration_list
	: class_content_element*
	;
	
class_content_element
	: access_specifier ':'
	| (declaration_specifiers declarator '{') => function_definition 
	| in_class_declaration
	;
	
constructor_definition
	: className '(' parameter_type_list? ')' compound_statement
	;
	
constructor_declaration
	: className '(' parameter_type_list? ')' ';'
	;
	
destructor_definition
	: '~'className '(' ')' compound_statement
	;
	
destructor_declaration
	: '~'className '(' ')' ';'
	;

className
	: IDENTIFIER
	;
	
in_class_declaration
	: /*(struct_union_or_class IDENTIFIER ':' 'public') => struct_union_or_class_definition ';'
	| (struct_union_or_class IDENTIFIER '{') => struct_union_or_class_definition ';'
	| simple_declaration ';'
	| template_declaration
	| 'typedef' simple_declaration ';'*/
	  (declaration_specifiers? declarator '{' )=> function_definition
	|  declaration
	| (constructor_definition | constructor_declaration)
	| (destructor_definition | destructor_declaration)
	;
	
inclass_function_definition
	: specifier_qualifier_list declarator compound_statement
	;

specifier_qualifier_list //fix me
	: (storage_class_specifier
           |   type_qualifier
           |   function_specifier
           |   type_specifier
           |   'friend')+
	;

class_declarator_list
	: class_declarator (',' class_declarator)*
	;

class_declarator
	: declarator (':' constant_expression)?
	| ':' constant_expression
	;

enum_specifier
options {k=3;}
	: 'enum' '{' enumerator_list '}'
	| 'enum' IDENTIFIER '{' enumerator_list '}'
	| 'enum' IDENTIFIER
	;

enumerator_list
	: enumerator (',' enumerator)*
	;

enumerator
	: IDENTIFIER ('=' constant_expression)?
	;

type_qualifier
	: 'const'
	  {
	    $cv_qual::constCount++;
	  }
	  {const_count_error() == true}?
	| 'volatile'
	  {
	    $cv_qual::volatileCount++;
	  }
	  {volatile_count_error() == true}?
	;

declarator
scope{
	ArrayList<ptr_cv> pointers;
}
@init{
	$declarator::pointers = null;
}
	: { $declarator::pointers = new ArrayList<ptr_cv>(); } 
	p = pointer[$declarator::pointers]? direct_declarator 
					    { 
					    	if($p.tree != null){
					    		ptr_cv quals = $declarator::pointers.get(0);
					    		Pointer ptr = new Pointer(null, quals.isConst, quals.isVolatile);
					    		Pointer pending = ptr;
					    		for(int i = 1 ; i < $declarator::pointers.size() ; ++i){
					    			quals = $declarator::pointers.get(i);
					    			Pointer temp = new Pointer(null, quals.isConst, quals.isVolatile);
					    			pending.setPointsTo(temp);
					    			pending = temp;
					    		}
						    	if($decl_infered::declarator == null){
						    		$decl_infered::declarator = new DeclaratorInferedType(ptr, pending);
						    	}
						    	else{
						    		$decl_infered::declarator.setPending(ptr, pending);
						    	}
					    	}
					    }
	//| pointer
	;



direct_declarator
	:   ( IDENTIFIER { $declarator_strings::dir_decl_identifier = $IDENTIFIER.text;
			   if($parameter_declaration.size() > 0) $parameter_declaration::p.id = $IDENTIFIER.text;
			   if($decl_id_info.size() > 0){
			   	$decl_id_info::line = this.fixLine($IDENTIFIER);
			   	$decl_id_info::pos = $IDENTIFIER.pos;
			   }
			   if(pending_undeclared_err != null) pending_undeclared_err = null;
			   direct_declarator_error($IDENTIFIER.text, this.fixLine($IDENTIFIER), $IDENTIFIER.pos, $declarator_strings::dir_decl_error); }
			//{
			//if ($declaration.size()>0&& ($declaration::isTypedef)) {
			//	$Symbols::types.add($IDENTIFIER.text);
			//	System.out.println("define type "+$IDENTIFIER.text);
			//}
			//}
		|	'(' dcl = declarator ')'
		)
        	declarator_suffix*
	;

declarator_suffix
scope cv_qual;
@init{
	cv_qual_at_init();
}
	:'[' constant_expression? r_bracket = ']'
	  {
	  	CpmArray ar = new CpmArray(null, 1);
	  	if($decl_infered::declarator == null){
	    		$decl_infered::declarator = new DeclaratorInferedType(ar);
	    	}
	    	else{
	    		try{
	    			$decl_infered::declarator.setPending(ar);
	    		}
	    		catch(Exception ex){
	    			this.yield_error("error: '" + $declarator_strings::dir_decl_identifier + '\'' + " " + ex.getMessage(),
	    					  this.fixLine($r_bracket),
	    					  $r_bracket.getCharPositionInLine());
	    		}
	    	}
	  }
    	|'(' parameter_type_list? r_paren = ')' (type_qualifier+)? pure_virt_method_specifier?
    	  {
    	  	boolean isConst = $cv_qual::constCount != 0 ? true : false, 
    	  		isVolatile = $cv_qual::volatileCount != 0 ? true : false,
    	  		isAbstract = $pure_virt_method_specifier.tree != null ? true : false;
    	  	
    	  	Method m = null;
    	  	ParameterList ps = null;
    	  	if($parameter_type_list.tree != null){
    	  		ps = $parameter_type_list.params;
    	  		if(ps != null){
    	  			/*
    	  			 * virtual = false here because this flag is available in an other level
    	  			 */
    	  			m = new Method(null, ps.params, this.symbolTable.getCurrentNamespace(),
    	  				       false, isAbstract, isConst, isVolatile);
    	  		}
    	  	}
    	  	else{
    	  		m = new Method(null, null, this.symbolTable.getCurrentNamespace(),
    	  			       false, isAbstract, isConst, isVolatile);
    	  	}
    	  	
    	  	if(m != null){
			DeclaratorInferedType d_inf_t = $decl_infered::declarator;
			
			if(d_inf_t == null){
				$decl_infered::declarator = new DeclaratorInferedType(m);
				if($parameter_type_list.tree != null && $function_definition.size() > 0){
					$function_definition::parameters_ids = ps.ids;
				}
			}
			else{
				try{
					d_inf_t.setPending(m);
				}
				catch(Exception ex){
					this.yield_error("error: '" + $declarator_strings::dir_decl_identifier + '\'' + " " + ex.getMessage(),
							 this.fixLine($r_paren),
							 $r_paren.getCharPositionInLine());
				}
			}
    	  	}
    	  }
    	//|'(' identifier_list? ')'									//maybe K&R style
    	//|'(' ')' const_method_specifier? pure_virt_method_specifier? == rule3 with parameter_type_list?
	;

pure_virt_method_specifier
	: ('=' '0')
	;

pointer [ArrayList<ptr_cv> pointers]
scope cv_qual;
@init{
	this.cv_qual_at_init();
}
	: '*' type_qualifier+ 
	      {
	      	 $pointers.add(new ptr_cv(($cv_qual::constCount != 0 ? true : false), ($cv_qual::volatileCount != 0 ? true : false)));
	      }
	      pointer[pointers]?
	| '*'
	  {
	  	$pointers.add(new ptr_cv(false, false));
	  }
	  pointer[pointers]
	| '*' { $pointers.add(new ptr_cv(false, false)); }
	;

parameter_type_list returns [ParameterList params]
scope{
	ParameterList p_list;
	boolean error_in_parameters;
}
	: {
	   $parameter_type_list::p_list = new ParameterList();
	   $parameter_type_list::error_in_parameters = false;
	  } 
	  parameter_list (',' varargs = '...')? 
	  {
	    if($parameter_type_list::error_in_parameters == true) $params = null;
	    else{
	      $parameter_type_list::p_list.hasVarargs = ($varargs != null) ? true : false;
	      $params = $parameter_type_list::p_list;
	    }
	  }
	;

parameter_list
	: param_decl1 = parameter_declaration
	  //{ this.state.backtracking > 0 || $param_decl1.param != null }?
	  { if($param_decl1.param != null){
	  	$parameter_type_list::p_list.insertParam($param_decl1.param);
	    }
	    else{
	    	$parameter_type_list::error_in_parameters = true;
	    }
	  }
	 (',' param_decl2 = parameter_declaration
	  //{ this.state.backtracking > 0 || $param_decl2.param != null }?
	  { if($param_decl2.param != null){
	  	$parameter_type_list::p_list.insertParam($param_decl2.param);
	    }
	    else{
	    	$parameter_type_list::error_in_parameters = true;
	    }
	  }
	  )*
	;
	catch [FailedPredicateException _]{
		/*
		 * don't show the error message from the predicate
		 * all error messages are being handle inside parameter_declaration rule
		 */
	}

parameter_declaration returns [Param param]
scope{
	Param p;
}
scope declarator_strings;
scope decl_infered;
@init{
	$declarator_strings::dir_decl_identifier = null;
	$declarator_strings::dir_decl_error = null;
	$decl_infered::declarator = null;
}
	: { $parameter_declaration::p = new Param(); }
	  declaration_specifiers
	  {
	  	if($declaration_specifiers.error != null){
	  		$declarator_strings::dir_decl_error = $declaration_specifiers.error + $declaration_specifiers.init_decl_err;
	  	}
	  }
	  (d = declarator | ad = abstract_declarator)?
	  {
	  	Type data_type = $declaration_specifiers.t;
	  	if(data_type != null){
		  	DeclaratorInferedType decl_inf_t = $decl_infered::declarator;
		  	String declarator_id = $declarator_strings::dir_decl_identifier;
		  	if(decl_inf_t == null) {
		  		$parameter_declaration::p.t = data_type;
		  		$param = $parameter_declaration::p;
		  	}
		  	else{
		  		boolean error_in_declarator = false;
		  		if(decl_inf_t.p_pend != null){
		  			decl_inf_t.p_pend.setPointsTo(data_type);
		  		}
		  		else if(decl_inf_t.m_pend != null){
		  			decl_inf_t.m_pend.getSignature().setReturnValue(data_type);
		  		}
		  		else if(decl_inf_t.ar_pend != null){
		  			decl_inf_t.ar_pend.setType(data_type);
		  		}
		  		else{
		  			error_in_declarator = true;
		  		}
		  		
		  		if(error_in_declarator == false){
			  		if(decl_inf_t.p_rv != null){
			  			$parameter_declaration::p.t = decl_inf_t.p_rv;
			  		}
			  		else if(decl_inf_t.m_rv != null){
			  			$parameter_declaration::p.t = decl_inf_t.m_rv;
			  		}
			  		else if(decl_inf_t.ar_rv != null){
			  			$parameter_declaration::p.t = decl_inf_t.ar_rv;
			  		}
			  		$param = $parameter_declaration::p;
		  		}
		  		else{
		  			$param = null;
		  		}
		  	}
		  }
		  else{
		  	$param = null;
		  	if($d.tree == null && $ad.tree == null){
			  	if($declarator_strings::dir_decl_error != null){
			  		Token end_t = $declaration_specifiers.stop;
			  		int line = this.fixLine(end_t);
			  		int pos = end_t.getCharPositionInLine();
			  		this.yield_error($declarator_strings::dir_decl_error + " 'parameter'", line, pos);
			  	}
		  	}
		  }
	  }
	;

identifier_list
	: IDENTIFIER (',' IDENTIFIER)*
	;

type_name
	: specifier_qualifier_list abstract_declarator?
	;

abstract_declarator
scope{
	ArrayList<ptr_cv> pointers;
}
@init{
	$declarator_strings::dir_decl_identifier = "parameter";
}
	: { 
	    $abstract_declarator::pointers = new ArrayList<ptr_cv>();
	    if($declarator_strings::dir_decl_error != null){
		Token next_tok = this.input.LT(1);
		int line = this.fixLine(next_tok);
		int pos = next_tok.getCharPositionInLine();
		this.yield_error($declarator_strings::dir_decl_error + " 'parameter'", line, pos);
	     } 
	  }
	  pointer[$abstract_declarator::pointers]
	  direct_abstract_declarator?
	  {
	  	ptr_cv quals = $abstract_declarator::pointers.get(0);
    		Pointer ptr = new Pointer(null, quals.isConst, quals.isVolatile);
    		Pointer pending = ptr;
    		for(int i = 1 ; i < $abstract_declarator::pointers.size() ; ++i){
    			quals = $abstract_declarator::pointers.get(i);
    			Pointer temp = new Pointer(null, quals.isConst, quals.isVolatile);
    			pending.setPointsTo(temp);
    			pending = temp;
    		}
	    	if($decl_infered::declarator == null){
	    		$decl_infered::declarator = new DeclaratorInferedType(ptr, pending);
	    	}
	    	else{
	    		$decl_infered::declarator.setPending(ptr, pending);
	    	}
	  }
	| direct_abstract_declarator
	;

direct_abstract_declarator
	:	( '(' par_decl = abstract_declarator ')' | decl_suf = declarator_suffix ) decl_suffixes += declarator_suffix*
	;


initializer
	: assignment_expression
	| '{' initializer_list ','? '}'
	;

initializer_list
	: initializer (',' initializer)*
	;

// E x p r e s s i o n s

argument_expression_list
	:   assignment_expression (',' assignment_expression)*
	;

additive_expression
	: (multiplicative_expression) ('+' multiplicative_expression | '-' multiplicative_expression)*
	;

multiplicative_expression
	: (cast_expression) ('*' cast_expression | '/' cast_expression | '%' cast_expression)*
	;

cast_expression
	: '(' type_name ')' cast_expression
	| unary_expression
	;

unary_expression
	: postfix_expression
	| '++' unary_expression
	| '--' unary_expression
	| unary_operator cast_expression
	| 'sizeof' unary_expression
	| 'sizeof' '(' type_name ')'
	;

postfix_expression
	:   primary_expression
        (   '[' expression ']'
        |   '(' ')'
        |   '(' argument_expression_list ')'
        |   '.' IDENTIFIER
        |   '->' IDENTIFIER
        |   '++'
        |   '--'
        )*
	;

unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

constant
    :   HEX_LITERAL
    |   OCTAL_LITERAL
    |   DECIMAL_LITERAL
    |	CHARACTER_LITERAL
    |	STRING_LITERAL
    |   FLOATING_POINT_LITERAL
    ;
    
primary_expression
	: constant
	| IDENTIFIER // --> nested_name_id
	| 'this'
	| '(' expression ')'
	;

 
expression
	: assignment_expression (',' assignment_expression)*
	;

constant_expression
	: conditional_expression
		;

assignment_expression
	: lvalue assignment_operator assignment_expression -> ^(assignment_expression lvalue assignment_expression)
	| conditional_expression
	| new_exp
	;
new_exp
	: 'new' nested_name_id ('('argument_expression_list?')')?
	;

	
lvalue
	:	unary_expression
	;

assignment_operator
	: '='
	| '*='
	| '/='
	| '%='
	| '+='
	| '-='
	| '<<='
	| '>>='
	| '&='
	| '^='
	| '|='
	;

conditional_expression
	: logical_or_expression ('?' expression ':' conditional_expression)?
	;

logical_or_expression
	: logical_and_expression ('||' logical_and_expression)*
	;

logical_and_expression
	: inclusive_or_expression ('&&' inclusive_or_expression)*
	;

inclusive_or_expression
	: exclusive_or_expression ('|' exclusive_or_expression)*
	;

exclusive_or_expression
	: and_expression ('^' and_expression)*
	;

and_expression
	: equality_expression ('&' equality_expression)*
	;
equality_expression
	: relational_expression (('=='|'!=') relational_expression)*
	;

relational_expression
	: shift_expression (('<'|'>'|'<='|'>=') shift_expression)*
	;

shift_expression
	: additive_expression (('<<'|'>>') additive_expression)*
	;

// S t a t e m e n t s

statement
	: labeled_statement
	| compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	;

labeled_statement
	: IDENTIFIER ':' statement
	| 'case' constant_expression ':' statement
	| 'default' ':' statement
	;

compound_statement
	: '{' (declaration | statement)* '}'				//not only at the begining
	;

statement_list
	: statement+
	;

expression_statement
	: ';'
	| expression ';'
	;

selection_statement
	: 'if' '(' expression ')' statement (options {k=1; backtrack=false;}:'else' statement)?
	| 'switch' '(' expression ')' statement
	;

iteration_statement
	: 'while' '(' expression ')' statement
	| 'do' statement 'while' '(' expression ')' ';'
	| 'for' '(' init_for_iteration_stmt expression_statement expression? ')' statement
	;
	
init_for_iteration_stmt
	: //simple_declaration
	  expression_statement
	;

jump_statement
	: 'goto' IDENTIFIER ';'
	| 'continue' ';'
	| 'break' ';'
	| 'return' ';'
	| 'return' expression ';'
	;
	
//Preprocessor

/*
 * Instead of explicitly put 1,2,3,4 as flags
 * I put DECIMAL_LITERAL lexer rule because 
 * there is obviosly a conflict between these two.
 * And of course in this phase the output would be correct,
 * because it comes from cpp
 */
 
line_marker
scope{
	boolean is_enter;
	boolean is_exit;
}
@init{
	$line_marker::is_enter = false;
	$line_marker::is_exit = false;
}
	: h_tag = '#' DECIMAL_LITERAL STRING_LITERAL line_marker_flags? { String file = $STRING_LITERAL.text;
									  file = file.substring(1, file.length() - 1);
									  int baseLine = Integer.parseInt($DECIMAL_LITERAL.text);
									  int preprocLine = $h_tag.line;
									  //ignore preproc useless stuff 
									  if(file.equals("<built-in>") == false && file.equals("<command-line>") == false){
										  if($line_marker::is_enter == true){
										  	this.preproc.enterIncludedFile(file, 
										  				       baseLine,
										  				       preprocLine,
										  				       this.fixLine($h_tag));
										  }
										  else if($line_marker::is_exit == true){
										  	this.preproc.exitIncludedFile(baseLine, preprocLine);
										  }
										  else{
										  	this.preproc.enterIncludedFile(file,
										  				       baseLine,
										  				       preprocLine,
										  				       preprocLine);
										  }
									  }
									}
	;

line_marker_flags
	: DECIMAL_LITERAL
	  {
	  	int flag = Integer.parseInt($DECIMAL_LITERAL.text);
	  	if(flag == 1) $line_marker::is_enter = true;
	  	else if(flag == 2) $line_marker::is_exit = true;
	  }
	  line_marker_flags
	| DECIMAL_LITERAL
	  {
	  	int flag = Integer.parseInt($DECIMAL_LITERAL.text);
	  	if(flag == 1) $line_marker::is_enter = true;
	  	else if(flag == 2) $line_marker::is_exit = true;
	  }
	;

IDENTIFIER
	:	LETTER (LETTER|'0'..'9')*
	;

fragment
LETTER
	:	'$'
	|	'A'..'Z'
	|	'a'..'z'
	|	'_'
	;

CHARACTER_LITERAL
    :   '\'' ( EscapeSequence | ~('\''|'\\') ) '\''
    ;

STRING_LITERAL
    :  '"' ( EscapeSequence | ~('\\'|'"') )* '"'
    ;

fragment
ZERO 	: '0';
DECIMAL_LITERAL
	: (ZERO | '1'..'9' '0'..'9'*) IntegerTypeSuffix?
	;

OCTAL_LITERAL : '0' ('0'..'7')+ IntegerTypeSuffix?
	      ;

HEX_LITERAL : '0' ('x'|'X') HexDigit+ IntegerTypeSuffix?
	    ;

fragment
HexDigit : ('0'..'9'|'a'..'f'|'A'..'F') ;

fragment
IntegerTypeSuffix
options{greedy = true;}
	:	('u'|'U')? ('l'|'L')
	|	('u'|'U')  ('l'|'L')?
	;

FLOATING_POINT_LITERAL
options{greedy = true;}
    :   ('0'..'9')+ '.' ('0'..'9')* Exponent? FloatTypeSuffix?
    |   '.' ('0'..'9')+ Exponent? FloatTypeSuffix?
    |   ('0'..'9')+ Exponent FloatTypeSuffix?
    |   ('0'..'9')+ Exponent? FloatTypeSuffix
	;

fragment
Exponent : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

fragment
FloatTypeSuffix : ('f'|'F'|'d'|'D') ;

fragment
EscapeSequence
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    |   OctalEscape
    ;

fragment
OctalEscape
    :   '\\' ('0'..'3') ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7')
    ;

fragment
UnicodeEscape
    :   '\\' 'u' HexDigit HexDigit HexDigit HexDigit
    ;

WS  :  (' '|'\r'|'\t'|'\u000C'|'\n') { if(this.ignore_ws == true) $channel=HIDDEN; }
    ;

COMMENT
    :   '/*' ( options {greedy=false;} : . )* '*/' {$channel=HIDDEN;}
    ;

LINE_COMMENT
    : '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    ;


// ignore #line info for now
//LINE_COMMAND 
//    : '#' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
//    ;