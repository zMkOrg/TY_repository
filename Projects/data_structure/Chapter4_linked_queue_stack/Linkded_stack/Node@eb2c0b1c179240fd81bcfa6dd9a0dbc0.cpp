#include "Node.h"

Node::Node()
{
	next = nullptr;
}
Node::Node(Node_entry item, Node *add_on = nullptr)
{
	entry = item;
	next = add_on;
}
