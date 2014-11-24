#include "qt/element/QtStatusBar.h"

QtStatusBar::QtStatusBar()
    : m_text(this)
{
	m_text.setText("hallo test test");
	addWidget(&m_text);
}

QtStatusBar::~QtStatusBar()
{
}

void QtStatusBar::setText(const std::string& text, bool isError)
{
	if (isError)
	{
		m_text.setStyleSheet("QLabel { color: red }");
	}
	m_text.setText(text.c_str());
}
