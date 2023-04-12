import random

from mutations.base import Base
import visitors.single_statement_line_collector as sslv
import transformers.single_statement_line_remover as sslr


class mDL(Base):
    def call(self):
        visitor = sslv.SingleStatementLineCollector()
        self.source_tree.visit(visitor)
        result = visitor.result

        deletionDict = {}
        nodeHash, node = random.choice(list(result.data.items()))
        deletionDict[nodeHash] = node

        transformer = sslr.SingleStatementLineRemover(deletionDict)
        modified_tree = self.source_tree.visit(transformer)

        return modified_tree
