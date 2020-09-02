import macros
import tables

export tables.add, tables.`[]`

func procIsExported(procDef: NimNode): bool =
  let nameNode = procDef[0]
  case nameNode.kind
  of nnkIdent:
    false
  of nnkPostfix:
    true
  else:
    raise newException(ValueError, "Invalid proc node")

func createProcNameNode(nameNode: NimNode; isExported: bool): NimNode =
  if isExported:
    nnkPostfix.newTree(ident("*"), nameNode)
  else:
    nameNode

macro memoize*(node: untyped): untyped =
  # echo node.astGenRepr

  result = newStmtList()

  let
    originalProcIsExported = procIsExported(node)
    originalProcName =
      if originalProcIsExported:
        node[0][1].strVal
      else:
        node[0].strVal
    newProcNameNode = genSym(nskProc, originalProcName & "Proc")
    formalParamsNode = node[3]  # includes the return type
    returnTypeNode = formalParamsNode[0]
    
  var
    tupleTypeExpr = nnkPar.newTree()
    tableKeyExpr = nnkPar.newTree()
    callExpr = nnkCall.newTree(newProcNameNode)
  for child in formalParamsNode:
    if child.kind != nnkIdentDefs:
      continue
    tupleTypeExpr.add ident(child[1].strVal)
    tableKeyExpr.add ident(child[0].strVal)
    callExpr.add ident(child[0].strVal)
  let tableNameNode = genSym(nskVar, originalProcName & "Table")

  # table declaration
  let tableDecl = quote do:
    var `tableNameNode` = initTable[`tupleTypeExpr`, `returnTypeNode`]()
  result.add(tableDecl)

  # forward-declaration
  var fwDeclNode = copyNimTree(node)
  fwDeclNode[0] = copyNimNode(newProcNameNode)
  # fwDeclNode[6] = newEmptyNode()
  fwDeclNode[6] = newStmtList()  # see https://github.com/nim-lang/Nim/issues/13484 ...
  result.add(fwDeclNode)

  # helper proc declaration
  var newProcDecl = nnkProcDef.newTree(
    createProcNameNode(ident(originalProcName), originalProcIsExported),
    newEmptyNode(),  # unused for procs
    newEmptyNode(),  # generic params
    formalParamsNode,
    newEmptyNode(),  # pragmas
    newEmptyNode(),  # reserved
  )
  newProcDecl.add quote do:  # the body of the lookup proc
    # echo "helper proc... ", `tableKeyExpr`
    if `tableNameNode`.hasKey(`tableKeyExpr`):
      result = `tableNameNode`[`tableKeyExpr`]
    else:
      let y = `callExpr`
      `tableNameNode`.add(`tableKeyExpr`, y)
      result = y
  result.add(newProcDecl)

  # add the renamed original proc declaration
  node[0] = createProcNameNode(newProcNameNode, originalProcIsExported)
  result.add(node)
  
  # echo result.repr

when isMainModule:
  const
    N = 10
    NOnTwo = 10 shr 1
    NTwice = 10 shl 1

  proc fib(n: int): int {.memoize.} =
    echo "\tcompute... ", n
    doAssert(n >= 0)
    if n < 2: n
    else: fib(n - 1) + fib(n - 2)
  
  echo "fib(" & $N & "):"
  echo fib(N)
  echo "fib(" & $N & "):"
  echo fib(N)
  echo "fib(" & $NOnTwo & "):"
  echo fib(NOnTwo)
  echo "fib(" & $NTwice & "):"
  echo fib(NTwice)
